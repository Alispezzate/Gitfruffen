import 'package:flutter/material.dart';

import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_layout.dart';

/// Paints a single commit-graph row.
///
/// [row] is the layout for the row; [laneWidth] is the horizontal spacing
/// between lanes and [rowHeight] the vertical space allotted to the row. The
/// painter draws lines that enter from the top and leave through the bottom so
/// consecutive rows connect seamlessly.
class CommitGraphPainter extends CustomPainter {
  const CommitGraphPainter({
    required this.row,
    required this.laneCount,
    required this.palette,
    this.rowHeight = 64,
    this.laneWidth = 18,
    this.topInset = 0,
  });

  final GraphRow row;

  /// Total lanes in the graph, used to size the gutter.
  final int laneCount;

  /// Colours cycled by lane colour index.
  final List<Color> palette;
  final double rowHeight;
  final double laneWidth;

  /// Vertical offset of the node within the row.
  final double topInset;

  double _x(int lane) => laneWidth / 2 + lane * laneWidth;

  Color _color(int index) => palette[index % palette.length];

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = topInset + rowHeight / 2;
    final nodeLane = _x(row.nodeLane);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final nodePaint = Paint()..style = PaintingStyle.fill;

    // Pass-through lanes: straight vertical lines.
    for (final lane in row.passthrough) {
      linePaint.color = _color(lane.colorIndex);
      final x = _x(lane.lane);
      canvas.drawLine(Offset(x, 0), Offset(x, rowHeight), linePaint);
    }

    // Node lane entering from the top: a straight segment down to the node.
    if (row.nodeFromTop) {
      linePaint.color = _color(row.nodeColorIndex);
      canvas.drawLine(
        Offset(nodeLane, 0),
        Offset(nodeLane, centerY),
        linePaint,
      );
    }

    // Merge lanes entering from the top and curving into the node.
    for (final lane in row.mergeIn) {
      linePaint.color = _color(lane.colorIndex);
      final x = _x(lane.lane);
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x, centerY - laneWidth)
        ..quadraticBezierTo(x, centerY, nodeLane, centerY)
        ..lineTo(nodeLane, centerY);
      canvas.drawPath(path, linePaint);
    }

    // First parent: straight line from the node down.
    if (row.nodeDown) {
      linePaint.color = _color(row.nodeColorIndex);
      canvas.drawLine(
        Offset(nodeLane, centerY),
        Offset(nodeLane, rowHeight),
        linePaint,
      );
    }

    // Extra parents: lines leaving the node towards the bottom.
    for (final lane in row.branchOut) {
      linePaint.color = _color(lane.colorIndex);
      final x = _x(lane.lane);
      final path = Path()
        ..moveTo(nodeLane, centerY)
        ..quadraticBezierTo(x, centerY, x, centerY + laneWidth)
        ..lineTo(x, rowHeight);
      canvas.drawPath(path, linePaint);
    }

    // Node.
    nodePaint.color = _color(row.nodeColorIndex);
    canvas.drawCircle(Offset(nodeLane, centerY), 4, nodePaint);
  }

  @override
  bool shouldRepaint(CommitGraphPainter oldDelegate) =>
      oldDelegate.row != row ||
      oldDelegate.laneCount != laneCount ||
      oldDelegate.palette != palette ||
      oldDelegate.rowHeight != rowHeight ||
      oldDelegate.laneWidth != laneWidth ||
      oldDelegate.topInset != topInset;
}
