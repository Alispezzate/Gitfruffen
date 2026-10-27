import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/dialogs/repository_dialogs.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_view.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/changes_panel.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/commit_composer.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/commit_details_panel.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/file_diff_view.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/repository_sidebar.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/resize_handle.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/terminal_panel.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/workspace_header.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Three-pane repository workspace.
///
/// A header sits on top; below it the left sidebar holds the repository refs,
/// the centre shows the commit graph and the right panel shows the working
/// tree changes or the selected commit. An optional terminal spans the centre
/// and right panes.
class RepositoryPage extends StatelessWidget {
  const RepositoryPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RepositoryBloc, RepositoryState>(
        buildWhen: (previous, next) =>
            previous.active != next.active ||
            previous.runtimeType != next.runtimeType ||
            previous.isBusy != next.isBusy,
        builder: (context, state) {
          final active = state.active;
          final l10n = AppLocalizations.of(context);
          if (active == null) {
            return switch (state) {
              RepositoryInitial() => AppEmptyState(
                icon: Icons.folder_off_outlined,
                title: l10n.emptyNoRepository,
                message: l10n.emptyNoRepositoryMessage,
              ),
              RepositoryLoading() => AppLoading(
                message: l10n.openingRepository,
              ),
              RepositoryError(:final failure) => AppErrorView(
                message: failure.message,
                onRetry: () => openRepositoryDialog(context),
              ),
              RepositoryReady() => AppEmptyState(
                icon: Icons.folder_off_outlined,
                title: l10n.emptyNoRepository,
              ),
            };
          }
          return _Workspace(tab: active);
        },
      );
}

class _Workspace extends StatefulWidget {
  const _Workspace({required this.tab});

  final RepositoryTab tab;

  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  static const double _minPane = 180;
  static const double _maxPane = 520;
  static const double _minRightPane = 260;
  static const double _maxRightPane = 520;

  double _leftWidth = AppTheme.sidebarWidth;
  double _rightWidth = 380;
  bool _terminalVisible = false;
  bool _terminalExpanded = true;
  OpenFileRequest? _openFile;

  @override
  void didUpdateWidget(_Workspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTab = oldWidget.tab;
    final tab = widget.tab;
    if (oldTab.repository.path != tab.repository.path ||
        oldTab.selectedCommitOid != tab.selectedCommitOid ||
        oldTab.stagedDiff != tab.stagedDiff ||
        oldTab.unstagedDiff != tab.unstagedDiff ||
        oldTab.commitDiff != tab.commitDiff) {
      _openFile = null;
    }
  }

  void _resizeLeft(double delta) {
    setState(() {
      _leftWidth = (_leftWidth + delta).clamp(_minPane, _maxPane);
    });
  }

  void _resizeRight(double delta) {
    setState(() {
      _rightWidth = (_rightWidth - delta).clamp(_minRightPane, _maxRightPane);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 1000;
    final showRight = width >= 900;
    return Column(
      children: [
        WorkspaceHeader(
          tab: widget.tab,
          leadingWidth: showSidebar ? _leftWidth : AppTheme.sidebarWidth,
          onToggleTerminal: () =>
              setState(() => _terminalVisible = !_terminalVisible),
        ),
        Expanded(
          child: Row(
            children: [
              if (showSidebar) ...[
                SizedBox(
                  width: _leftWidth,
                  child: RepositorySidebar(
                    key: ValueKey(widget.tab.repository.path),
                    tab: widget.tab,
                  ),
                ),
                ResizeHandle(onDragged: _resizeLeft),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ColoredBox(
                                color: theme.scaffoldBackgroundColor,
                                child: _openFile != null
                                    ? BlocProvider<FileDiffBloc>(
                                        key: ValueKey(_openFile),
                                        create: (context) => FileDiffBloc(
                                          repository: context
                                              .read<GitRepositoryContract>(),
                                          request: _openFile!,
                                        ),
                                        child: FileDiffView(
                                          onBack: () =>
                                              setState(() => _openFile = null),
                                        ),
                                      )
                                    : CommitGraphView(
                                        tab: widget.tab,
                                        selectedOid:
                                            widget.tab.selectedCommitOid,
                                        onCommitSelected: (commit) => context
                                            .read<RepositoryBloc>()
                                            .add(CommitSelected(commit.oid)),
                                        onWipSelected: () =>
                                            context.read<RepositoryBloc>().add(
                                              const CommitSelectionCleared(),
                                            ),
                                      ),
                              ),
                            ),
                            if (showRight) ...[
                              ResizeHandle(onDragged: _resizeRight),
                              Container(
                                width: _rightWidth,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  border: Border(
                                    left: BorderSide(color: theme.dividerColor),
                                  ),
                                ),
                                child: widget.tab.selectedCommitOid != null
                                    ? CommitDetailsPanel(
                                        tab: widget.tab,
                                        onOpenFile: (request) =>
                                            setState(() => _openFile = request),
                                      )
                                    : Column(
                                        children: [
                                          Expanded(
                                            child: ChangesPanel(
                                              tab: widget.tab,
                                              onOpenFile: (request) => setState(
                                                () => _openFile = request,
                                              ),
                                            ),
                                          ),
                                          CommitComposer(
                                            key: ValueKey(
                                              widget.tab.repository.path,
                                            ),
                                            tab: widget.tab,
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_terminalVisible)
                        TerminalPanel(
                          expanded: _terminalExpanded,
                          bodyHeight: math.min(
                            AppTheme.terminalBodyHeight,
                            constraints.maxHeight * 0.28,
                          ),
                          onToggle: () => setState(
                            () => _terminalExpanded = !_terminalExpanded,
                          ),
                          onClose: () =>
                              setState(() => _terminalVisible = false),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
