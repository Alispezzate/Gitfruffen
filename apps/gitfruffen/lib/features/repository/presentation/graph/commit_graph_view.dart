import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_layout.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_painter.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Commit graph at the centre of the repository workspace.
///
/// The lane gutter is a bounded, horizontally scrollable column so a repository
/// with many branches can never paint over the commit messages. It scrolls
/// vertically in lockstep with the commit list next to it.
class CommitGraphView extends StatefulWidget {
  const CommitGraphView({required this.tab, super.key});

  final RepositoryTab tab;

  @override
  State<CommitGraphView> createState() => _CommitGraphViewState();
}

class _CommitGraphViewState extends State<CommitGraphView> {
  static const double _rowHeight = 80;
  static const double _footerHeight = 64;
  static const double _laneWidth = 18;
  static const double _minGraphWidth = 40;
  static const double _maxGraphWidth = 260;
  static const double _threshold = 400;

  /// Vertical scroll of the commit list; kept in sync with [_laneController].
  final ScrollController _textController = ScrollController();

  /// Vertical scroll of the lane column; kept in sync with [_textController].
  final ScrollController _laneController = ScrollController();

  /// Horizontal scroll of the lane gutter.
  final ScrollController _graphController = ScrollController();

  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _textController
      ..addListener(_onTextScroll)
      ..addListener(_syncLanesFromText);
    _laneController.addListener(_syncTextFromLanes);
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
      ..removeListener(_syncLanesFromText)
      ..dispose();
    _laneController
      ..removeListener(_syncTextFromLanes)
      ..dispose();
    _graphController.dispose();
    super.dispose();
  }

  /// Mirrors [controller]'s offset onto [other], guarding against feedback.
  void _mirror(ScrollController controller, ScrollController other) {
    if (_syncing ||
        !controller.hasClients ||
        !other.hasClients ||
        other.offset == controller.offset) {
      return;
    }
    _syncing = true;
    other.jumpTo(
      controller.offset.clamp(
        other.position.minScrollExtent,
        other.position.maxScrollExtent,
      ),
    );
    _syncing = false;
  }

  void _syncLanesFromText() => _mirror(_textController, _laneController);

  void _syncTextFromLanes() => _mirror(_laneController, _textController);

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
    if (tab.graph.isEmpty) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: l10n.emptyNoCommits,
      );
    }

    final layout = CommitGraphLayoutBuilder.build(tab.graph);
    final palette = _palette(context);
    final decorations = _decorations(tab);
    final itemCount = tab.graph.length + 1;
    final graphWidth = math.max(
      _minGraphWidth,
      layout.laneCount * _laneWidth + _laneWidth / 2,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = math.min(
          graphWidth,
          math.min(_maxGraphWidth, constraints.maxWidth * 0.5),
        );
        return Row(
          children: [
            SizedBox(
              width: viewportWidth,
              child: _GraphLaneColumn(
                controller: _laneController,
                horizontalController: _graphController,
                width: graphWidth,
                itemCount: itemCount,
                itemBuilder: (context, index) =>
                    _laneFor(index, tab, layout, palette, graphWidth),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _textController,
                itemCount: itemCount,
                itemBuilder: (context, index) =>
                    _textFor(context, index, tab, decorations),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _laneFor(
    int index,
    RepositoryTab tab,
    CommitGraphLayout layout,
    List<Color> palette,
    double width,
  ) {
    if (index >= tab.graph.length) {
      return const SizedBox(height: _footerHeight);
    }
    final commit = tab.graph[index];
    final row = index < layout.rows.length
        ? layout.rows[index]
        : GraphRow(oid: commit.oid, nodeLane: 0, nodeColorIndex: 0);
    return SizedBox(
      width: width,
      height: _rowHeight,
      child: ClipRect(
        child: CustomPaint(
          painter: CommitGraphPainter(
            row: row,
            laneCount: layout.laneCount,
            palette: palette,
            rowHeight: _rowHeight,
          ),
        ),
      ),
    );
  }

  Widget _textFor(
    BuildContext context,
    int index,
    RepositoryTab tab,
    Map<String, List<String>> decorations,
  ) {
    if (index >= tab.graph.length) {
      return const SizedBox(height: _footerHeight, child: AppLoading());
    }
    final commit = tab.graph[index];
    return SizedBox(
      height: _rowHeight,
      child: _CommitDetails(
        commit: commit,
        decorations: decorations[commit.oid.value] ?? const [],
      ),
    );
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
  Map<String, List<String>> _decorations(RepositoryTab tab) {
    final result = <String, List<String>>{};
    for (final branch in tab.branches) {
      final oid = branch.targetOid;
      if (oid == null) {
        continue;
      }
      result.putIfAbsent(oid, () => []).add(branch.name);
    }
    for (final tag in tab.tags) {
      result.putIfAbsent(tag.targetOid, () => []).add(tag.name);
    }
    return result;
  }
}

/// Bounded lane gutter that scrolls horizontally and vertically.
///
/// The vertical list keeps its own controller, kept in sync with the commit
/// list, so dragging the gutter scrolls both panes together while horizontal
/// dragging reveals lanes beyond the viewport.
class _GraphLaneColumn extends StatelessWidget {
  const _GraphLaneColumn({
    required this.controller,
    required this.horizontalController,
    required this.width,
    required this.itemCount,
    required this.itemBuilder,
  });

  final ScrollController controller;
  final ScrollController horizontalController;
  final double width;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: horizontalController,
    notificationPredicate: (notification) =>
        notification.metrics.axis == Axis.horizontal,
    child: SingleChildScrollView(
      controller: horizontalController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        child: ListView.builder(
          controller: controller,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
    ),
  );
}

class _CommitDetails extends StatelessWidget {
  const _CommitDetails({required this.commit, required this.decorations});

  final Commit commit;
  final List<String> decorations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  commit.summary,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (commit.isMerge)
                Icon(Icons.merge_type, size: 14, color: theme.iconTheme.color),
            ],
          ),
          const SizedBox(height: 4),
          if (decorations.isNotEmpty)
            SizedBox(
              height: 18,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: decorations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) =>
                    _DecorationChip(label: decorations[index]),
              ),
            ),
          Text(
            l10n.commitSubtitle(commit.oid.short, commit.author.name),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DecorationChip extends StatelessWidget {
  const _DecorationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, color: AppColors.primary),
    ),
  );
}
