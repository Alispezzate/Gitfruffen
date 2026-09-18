import 'package:equatable/equatable.dart';
import 'package:git_core/git_core.dart';

/// A lane drawn across a single row: a column index plus the colour slot it
/// uses, so lines keep a stable colour as they travel down the graph.
class GraphLane extends Equatable {
  const GraphLane({required this.lane, required this.colorIndex});

  final int lane;
  final int colorIndex;

  @override
  List<Object?> get props => [lane, colorIndex];
}

/// Layout instructions for one commit row.
class GraphRow extends Equatable {
  const GraphRow({
    required this.oid,
    required this.nodeLane,
    required this.nodeColorIndex,
    this.nodeFromTop = false,
    this.passthrough = const [],
    this.mergeIn = const [],
    this.branchOut = const [],
    this.nodeDown = false,
  });

  final GitOid oid;

  /// Column of this commit's node.
  final int nodeLane;
  final int nodeColorIndex;

  /// Whether a lane enters this row from above at [nodeLane] and connects to
  /// the node. False when the node opens a brand-new lane.
  final bool nodeFromTop;

  /// Lanes that cross the row top to bottom without touching the node.
  final List<GraphLane> passthrough;

  /// Lanes entering from the top that converge into the node.
  final List<GraphLane> mergeIn;

  /// Lanes starting at the node that leave through the bottom.
  final List<GraphLane> branchOut;

  /// Whether the first parent continues straight down from the node.
  final bool nodeDown;

  @override
  List<Object?> get props => [
    oid,
    nodeLane,
    nodeColorIndex,
    nodeFromTop,
    passthrough,
    mergeIn,
    branchOut,
    nodeDown,
  ];
}

/// Result of laying out a commit list into graph rows.
class CommitGraphLayout extends Equatable {
  const CommitGraphLayout({required this.rows, required this.laneCount});

  final List<GraphRow> rows;

  /// Total number of lanes used, used to size the graph gutter.
  final int laneCount;

  static const CommitGraphLayout empty = CommitGraphLayout(
    rows: [],
    laneCount: 0,
  );

  @override
  List<Object?> get props => [rows, laneCount];
}

/// A lane slot waiting for a specific commit, with its stable colour slot.
class _Lane {
  _Lane({required this.target, required this.colorIndex});

  GitOid target;
  final int colorIndex;
}

/// Computes a top-down graph layout from commits ordered newest first.
///
/// The algorithm keeps a list of active lanes, each waiting for a specific
/// commit OID. When a commit is processed, the lane waiting for it (if any)
/// becomes the node lane; additional matching lanes merge into it. The commit's
/// parents continue on the node lane (first parent, drawn straight) or open new
/// lanes (merge parents). This yields the familiar branch/merge crossings of a
/// desktop Git client.
abstract final class CommitGraphLayoutBuilder {
  static CommitGraphLayout build(List<Commit> commits, {int colorCount = 8}) {
    if (commits.isEmpty) {
      return CommitGraphLayout.empty;
    }

    final lanes = <_Lane?>[];
    final rows = <GraphRow>[];
    var nextColor = 0;
    var laneCount = 0;

    int allocateColor() {
      final color = nextColor % colorCount;
      nextColor++;
      return color;
    }

    int findFreeLane() {
      for (var i = 0; i < lanes.length; i++) {
        if (lanes[i] == null) {
          return i;
        }
      }
      lanes.add(null);
      return lanes.length - 1;
    }

    int? laneWaiting(GitOid oid, int ignore) {
      for (var i = 0; i < lanes.length; i++) {
        if (i == ignore) {
          continue;
        }
        if (lanes[i] != null && lanes[i]!.target == oid) {
          return i;
        }
      }
      return null;
    }

    void grow(int lane) {
      if (lane + 1 > laneCount) {
        laneCount = lane + 1;
      }
    }

    for (final commit in commits) {
      final before = <int, int>{
        for (var i = 0; i < lanes.length; i++)
          if (lanes[i] != null) i: lanes[i]!.colorIndex,
      };

      final matched = <int>[
        for (var i = 0; i < lanes.length; i++)
          if (lanes[i] != null && lanes[i]!.target == commit.oid) i,
      ];

      final int nodeLane;
      final int nodeColor;
      if (matched.isEmpty) {
        nodeLane = findFreeLane();
        nodeColor = allocateColor();
      } else {
        nodeLane = matched.first;
        nodeColor = lanes[nodeLane]!.colorIndex;
      }
      grow(nodeLane);

      final mergeIn = <GraphLane>[
        for (final lane in matched.skip(1))
          GraphLane(lane: lane, colorIndex: lanes[lane]!.colorIndex),
      ];
      for (final lane in matched.skip(1)) {
        lanes[lane] = null;
      }

      final parents = commit.parentOids;
      final branchOut = <GraphLane>[];
      if (parents.isEmpty) {
        lanes[nodeLane] = null;
      } else {
        // The first parent always inherits the node lane, so its line runs
        // straight and continuous through the node.
        lanes[nodeLane] = _Lane(target: parents.first, colorIndex: nodeColor);

        for (final parent in parents.skip(1)) {
          final existing = laneWaiting(parent, nodeLane);
          if (existing != null) {
            branchOut.add(
              GraphLane(
                lane: existing,
                colorIndex: lanes[existing]!.colorIndex,
              ),
            );
            continue;
          }
          final lane = findFreeLane();
          final color = allocateColor();
          lanes[lane] = _Lane(target: parent, colorIndex: color);
          branchOut.add(GraphLane(lane: lane, colorIndex: color));
          grow(lane);
        }
      }

      final mergeLanes = {for (final m in mergeIn) m.lane};
      final passthrough = <GraphLane>[
        for (final entry in before.entries)
          if (entry.key != nodeLane && !mergeLanes.contains(entry.key))
            GraphLane(lane: entry.key, colorIndex: entry.value),
      ];

      rows.add(
        GraphRow(
          oid: commit.oid,
          nodeLane: nodeLane,
          nodeColorIndex: nodeColor,
          nodeFromTop: matched.isNotEmpty,
          passthrough: passthrough,
          mergeIn: mergeIn,
          branchOut: branchOut,
          nodeDown: parents.isNotEmpty,
        ),
      );
    }

    return CommitGraphLayout(rows: rows, laneCount: laneCount);
  }
}
