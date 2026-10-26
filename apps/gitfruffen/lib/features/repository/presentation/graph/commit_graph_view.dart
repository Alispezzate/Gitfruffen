import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_layout.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_painter.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Commit graph at the centre of the repository workspace.
///
/// A single vertical list renders every row - the WIP row, the commit rows and
/// the loading footer - so selection highlights span the full width and there
/// is nothing to keep in sync. The lane gutter has a fixed, capped width and
/// is clipped rather than horizontally scrolled.
class CommitGraphView extends StatefulWidget {
  const CommitGraphView({
    required this.tab,
    this.selectedOid,
    this.onCommitSelected,
    this.onWipSelected,
    super.key,
  });

  final RepositoryTab tab;
  final GitOid? selectedOid;
  final ValueChanged<Commit>? onCommitSelected;
  final VoidCallback? onWipSelected;

  @override
  State<CommitGraphView> createState() => _CommitGraphViewState();
}

class _CommitGraphViewState extends State<CommitGraphView> {
  static const double _rowHeight = AppTheme.graphRowHeight;
  static const double _footerHeight = 48;
  static const double _threshold = 400;

  final ScrollController _textController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoFill());
  }

  @override
  void didUpdateWidget(CommitGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.tab.graph, widget.tab.graph)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoFill());
    }
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_onTextScroll)
      ..dispose();
    super.dispose();
  }

  void _onTextScroll() {
    if (!_textController.hasClients) {
      return;
    }
    final position = _textController.position;
    if (position.pixels >= position.maxScrollExtent - _threshold) {
      _loadMore();
    }
  }

  void _autoFill() {
    if (!mounted || !_textController.hasClients) {
      return;
    }
    final position = _textController.position;
    if (position.maxScrollExtent <= 0 ||
        position.viewportDimension >= position.maxScrollExtent) {
      _loadMore();
    }
  }

  void _loadMore() {
    final tab = widget.tab;
    if (!tab.hasMoreGraph || tab.isLoadingMoreGraph) {
      return;
    }
    context.read<RepositoryBloc>().add(const RepositoryGraphLoadMore());
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final l10n = AppLocalizations.of(context);
    final hasChanges = tab.status.changes.isNotEmpty;
    if (tab.graph.isEmpty && !hasChanges) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: l10n.emptyNoCommits,
      );
    }

    final layout = tab.graph.isEmpty
        ? CommitGraphLayout.empty
        : CommitGraphLayoutBuilder.build(tab.graph);
    final palette = _palette(context);
    final refs = _refLabels(tab);
    final wipOffset = hasChanges ? 1 : 0;
    final itemCount = wipOffset + tab.graph.length + (tab.hasMoreGraph ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final refsWidth = math.min<double>(
          180,
          math.max<double>(120, constraints.maxWidth * 0.4),
        );
        final graphWidth = math.min<double>(
          200,
          math.max<double>(40, constraints.maxWidth - refsWidth - 100),
        );
        return Column(
          children: [
            _GraphHeader(refsWidth: refsWidth, graphWidth: graphWidth),
            Expanded(
              child: ListView.builder(
                controller: _textController,
                itemCount: itemCount,
                itemBuilder: (context, index) => _row(
                  context: context,
                  index: index,
                  tab: tab,
                  layout: layout,
                  palette: palette,
                  refs: refs,
                  refsWidth: refsWidth,
                  graphWidth: graphWidth,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row({
    required BuildContext context,
    required int index,
    required RepositoryTab tab,
    required CommitGraphLayout layout,
    required List<Color> palette,
    required Map<String, List<_RefLabel>> refs,
    required double refsWidth,
    required double graphWidth,
  }) {
    final hasChanges = tab.status.changes.isNotEmpty;
    if (hasChanges && index == 0) {
      return _wipRow(context, tab, refsWidth, graphWidth);
    }

    final commitIndex = index - (hasChanges ? 1 : 0);
    if (commitIndex >= tab.graph.length) {
      return const SizedBox(height: _footerHeight, child: AppLoading());
    }

    final commit = tab.graph[commitIndex];
    final row = commitIndex < layout.rows.length
        ? layout.rows[commitIndex]
        : GraphRow(oid: commit.oid, nodeLane: 0, nodeColorIndex: 0);
    final selected = widget.selectedOid == commit.oid;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      child: InkWell(
        onTap: widget.onCommitSelected == null
            ? null
            : () => widget.onCommitSelected!(commit),
        onSecondaryTapDown: (details) =>
            _showCommitMenu(context, details.globalPosition, commit),
        child: SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              SizedBox(
                width: refsWidth,
                child: _refsCell(refs[commit.oid.value] ?? const []),
              ),
              SizedBox(
                width: graphWidth,
                height: _rowHeight,
                child: ClipRect(
                  child: CustomPaint(
                    painter: CommitGraphPainter(
                      row: row,
                      laneCount: layout.laneCount,
                      palette: palette,
                    ),
                  ),
                ),
              ),
              Expanded(child: _messageCell(context, commit)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wipRow(
    BuildContext context,
    RepositoryTab tab,
    double refsWidth,
    double graphWidth,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final selected = widget.selectedOid == null;
    final insertions = tab.stagedDiff.insertions + tab.unstagedDiff.insertions;
    final deletions = tab.stagedDiff.deletions + tab.unstagedDiff.deletions;
    const textStyle = TextStyle(fontSize: 12);

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      child: InkWell(
        onTap: widget.onWipSelected,
        child: SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              SizedBox(
                width: refsWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '// ${l10n.wipLabel}',
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: graphWidth),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        l10n.wipLabel,
                        style: textStyle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.fileChangesSummary(tab.status.changes.length),
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                      if (insertions != 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '+$insertions',
                          style: textStyle.copyWith(color: AppColors.added),
                        ),
                      ],
                      if (deletions != 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '-$deletions',
                          style: textStyle.copyWith(color: AppColors.deleted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _refsCell(List<_RefLabel> labels) {
    final visible = labels.take(2).toList();
    final overflow = labels.length - visible.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final label in visible) ...[
            Flexible(child: _RefChip(label: label)),
            const SizedBox(width: 4),
          ],
          if (overflow > 0) _OverflowChip(label: '+$overflow'),
        ],
      ),
    );
  }

  Widget _messageCell(BuildContext context, Commit commit) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (commit.isMerge) ...[
            Icon(Icons.merge_type, size: 14, color: theme.iconTheme.color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              commit.summary,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCommitMenu(
    BuildContext context,
    Offset position,
    Commit commit,
  ) async {
    final l10n = AppLocalizations.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [PopupMenuItem(value: true, child: Text(l10n.copyShaButton))],
    );
    if (selected ?? false) {
      await Clipboard.setData(ClipboardData(text: commit.oid.value));
    }
  }

  List<Color> _palette(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      AppColors.primary,
      AppColors.secondary,
      AppColors.modified,
      AppColors.conflicted,
      scheme.tertiary,
      AppColors.deleted,
      AppColors.untracked,
      scheme.primaryContainer,
    ];
  }

  /// Maps each commit OID to the branch/tag labels pointing at it.
  Map<String, List<_RefLabel>> _refLabels(RepositoryTab tab) {
    final result = <String, List<_RefLabel>>{};
    for (final branch in tab.branches) {
      final oid = branch.targetOid;
      if (oid == null) {
        continue;
      }
      result
          .putIfAbsent(oid, () => [])
          .add(
            _RefLabel(
              name: branch.name,
              kind: branch.isRemote ? _RefKind.remote : _RefKind.local,
            ),
          );
    }
    for (final tag in tab.tags) {
      result
          .putIfAbsent(tag.targetOid, () => [])
          .add(_RefLabel(name: tag.name, kind: _RefKind.tag));
    }
    return result;
  }
}

enum _RefKind { local, remote, tag }

class _RefLabel {
  const _RefLabel({required this.name, required this.kind});

  final String name;
  final _RefKind kind;
}

/// Fixed column header aligned with the refs, graph and message cells.
class _GraphHeader extends StatelessWidget {
  const _GraphHeader({required this.refsWidth, required this.graphWidth});

  final double refsWidth;
  final double graphWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: refsWidth,
            child: _label(l10n.graphColumnBranchTag, style),
          ),
          SizedBox(
            width: graphWidth,
            child: _label(l10n.graphColumnGraph, style),
          ),
          Expanded(child: _label(l10n.graphColumnMessage, style)),
        ],
      ),
    );
  }

  Widget _label(String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    ),
  );
}

class _RefChip extends StatelessWidget {
  const _RefChip({required this.label});

  final _RefLabel label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (label.kind) {
      _RefKind.local => (
        AppColors.primary.withValues(alpha: 0.16),
        AppColors.primary,
      ),
      _RefKind.remote => (
        AppColors.untracked.withValues(alpha: 0.18),
        AppColors.untracked,
      ),
      _RefKind.tag => (
        AppColors.modified.withValues(alpha: 0.18),
        AppColors.modified,
      ),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 90),
      child: Container(
        height: 16,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: foreground),
        ),
      ),
    );
  }
}

class _OverflowChip extends StatelessWidget {
  const _OverflowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 16,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    ),
  );
}
