import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_layout.dart';

Commit commit(String sha, {List<String> parents = const []}) => Commit(
  oid: GitOid(sha),
  message: '$sha\n',
  summary: sha,
  author: Signature(
    name: 'Ada',
    email: 'ada@gitfruffen.dev',
    when: DateTime.utc(2026),
  ),
  committer: Signature(
    name: 'Ada',
    email: 'ada@gitfruffen.dev',
    when: DateTime.utc(2026),
  ),
  parentOids: [for (final parent in parents) GitOid(parent)],
);

void main() {
  group('CommitGraphLayoutBuilder', () {
    test('returns an empty layout for no commits', () {
      final layout = CommitGraphLayoutBuilder.build(const []);

      expect(layout.rows, isEmpty);
      expect(layout.laneCount, 0);
    });

    test('lays out a linear history on a single lane', () {
      final layout = CommitGraphLayoutBuilder.build([
        commit('3'.padLeft(40, '0'), parents: ['2'.padLeft(40, '0')]),
        commit('2'.padLeft(40, '0'), parents: ['1'.padLeft(40, '0')]),
        commit('1'.padLeft(40, '0')),
      ]);

      expect(layout.laneCount, 1);
      expect(layout.rows, hasLength(3));
      expect(layout.rows.every((row) => row.nodeLane == 0), isTrue);
      expect(layout.rows[0].nodeDown, isTrue);
      expect(layout.rows[2].nodeDown, isFalse);
    });

    test('opens a new lane for a merge commit parent', () {
      final layout = CommitGraphLayoutBuilder.build([
        commit(
          '3'.padLeft(40, '0'),
          parents: ['2'.padLeft(40, '0'), '1b'.padLeft(40, '0')],
        ),
        commit('2'.padLeft(40, '0'), parents: ['1'.padLeft(40, '0')]),
        commit('1b'.padLeft(40, '0'), parents: ['1'.padLeft(40, '0')]),
        commit('1'.padLeft(40, '0')),
      ]);

      expect(layout.laneCount, greaterThanOrEqualTo(2));
      expect(layout.rows.first.branchOut, hasLength(1));
      // The shared parent causes the two lanes to converge on one node.
      final mergeRow = layout.rows.first;
      expect(mergeRow.nodeLane, 0);
    });

    test('keeps lane colours stable across rows', () {
      final layout = CommitGraphLayoutBuilder.build([
        commit(
          '3'.padLeft(40, '0'),
          parents: ['2'.padLeft(40, '0'), '2b'.padLeft(40, '0')],
        ),
        commit('2'.padLeft(40, '0')),
        commit('2b'.padLeft(40, '0')),
      ]);

      final branchLane = layout.rows.first.branchOut.single;
      final secondRow = layout.rows[1];
      final drawn = [
        ...secondRow.passthrough,
        ...secondRow.mergeIn,
      ].where((lane) => lane.lane == branchLane.lane);
      expect(drawn.single.colorIndex, branchLane.colorIndex);
    });

    test('draws a continuous line into every node except new lane heads', () {
      final layout = CommitGraphLayoutBuilder.build([
        commit('3'.padLeft(40, '0'), parents: ['2'.padLeft(40, '0')]),
        commit('2'.padLeft(40, '0'), parents: ['1'.padLeft(40, '0')]),
        commit('1'.padLeft(40, '0')),
      ]);

      expect(layout.rows.first.nodeFromTop, isFalse);
      expect(layout.rows.skip(1).every((row) => row.nodeFromTop), isTrue);
    });

    test('lanes leaving a row match the lanes entering the next row', () {
      final layout = CommitGraphLayoutBuilder.build([
        commit(
          '5'.padLeft(40, '0'),
          parents: ['4'.padLeft(40, '0'), '3b'.padLeft(40, '0')],
        ),
        commit('4'.padLeft(40, '0'), parents: ['3'.padLeft(40, '0')]),
        commit('3b'.padLeft(40, '0'), parents: ['3'.padLeft(40, '0')]),
        commit('3'.padLeft(40, '0'), parents: ['2'.padLeft(40, '0')]),
        commit('2'.padLeft(40, '0')),
      ]);

      for (var i = 0; i < layout.rows.length - 1; i++) {
        expect(
          _bottomLanes(layout.rows[i]),
          _topLanes(layout.rows[i + 1]),
          reason: 'row $i does not connect to row ${i + 1}',
        );
      }
    });

    test('a merge parent continues straight down the same lane', () {
      final layout = CommitGraphLayoutBuilder.build([
        commit(
          '3'.padLeft(40, '0'),
          parents: ['2'.padLeft(40, '0'), '1b'.padLeft(40, '0')],
        ),
        commit('2'.padLeft(40, '0'), parents: ['1'.padLeft(40, '0')]),
        commit('1b'.padLeft(40, '0'), parents: ['1'.padLeft(40, '0')]),
        commit('1'.padLeft(40, '0')),
      ]);

      final merge = layout.rows.first;
      expect(merge.nodeLane, 0);
      expect(merge.nodeDown, isTrue);
      // First parent keeps lane 0; the second parent opens lane 1.
      expect(merge.branchOut.single.lane, 1);
      expect(layout.rows[1].nodeLane, 0);
      expect(layout.rows[1].nodeFromTop, isTrue);
      expect(layout.rows[2].nodeLane, 1);
      expect(layout.rows[2].nodeFromTop, isTrue);
      // Both branches converge on the shared root.
      expect(layout.rows[3].mergeIn, hasLength(1));
    });
  });
}

Set<int> _topLanes(GraphRow row) => {
  if (row.nodeFromTop) row.nodeLane,
  for (final lane in row.mergeIn) lane.lane,
  for (final lane in row.passthrough) lane.lane,
};

Set<int> _bottomLanes(GraphRow row) => {
  if (row.nodeDown) row.nodeLane,
  for (final lane in row.branchOut) lane.lane,
  for (final lane in row.passthrough) lane.lane,
};
