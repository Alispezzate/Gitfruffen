import 'package:flutter/material.dart';

/// A thin draggable divider that resizes its preceding pane horizontally.
///
/// Keeps the dependency footprint at zero while giving the workspace the
/// resizable three-pane layout of a desktop Git client.
class ResizeHandle extends StatelessWidget {
  const ResizeHandle({required this.onDragged, super.key, this.width = 6});

  /// Called with the horizontal delta in logical pixels while dragging.
  final ValueChanged<double> onDragged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDragged(details.delta.dx),
        child: Container(
          width: width,
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
