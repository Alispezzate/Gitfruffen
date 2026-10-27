import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/changed_files_list.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Working tree changes shown in the right panel, split into unstaged and
/// staged sections. Tapping a file asks the workspace to show its unified diff.
class ChangesPanel extends StatefulWidget {
  const ChangesPanel({required this.tab, required this.onOpenFile, super.key});

  final RepositoryTab tab;
  final ValueChanged<OpenFileRequest> onOpenFile;

  @override
  State<ChangesPanel> createState() => _ChangesPanelState();
}

class _ChangesPanelState extends State<ChangesPanel> {
  FileViewMode _mode = FileViewMode.path;
  bool _unstagedExpanded = true;
  bool _stagedExpanded = true;

  @override
  void didUpdateWidget(ChangesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.repository.path != widget.tab.repository.path) {
      _mode = FileViewMode.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final changes = tab.status.changes;
    final unstaged = changes.where((c) => c.unstaged || c.conflicted);
    final staged = changes.where((c) => c.staged && !c.conflicted);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.changesOnBranch(
                    changes.length,
                    tab.status.currentBranchName ?? '-',
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              FileViewModeToggle(
                mode: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              if (changes.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(
                    l10n.workingTreeClean,
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else ...[
                _Section(
                  title: l10n.unstagedFiles,
                  count: unstaged.length,
                  expanded: _unstagedExpanded,
                  actionLabel: l10n.stageAllChanges,
                  onAction: unstaged.isEmpty
                      ? null
                      : () => context.read<RepositoryBloc>().add(
                          const AllFilesStaged(),
                        ),
                  onToggle: () =>
                      setState(() => _unstagedExpanded = !_unstagedExpanded),
                  children: [
                    ChangedFilesList(
                      mode: _mode,
                      entries: [
                        for (final change in unstaged)
                          _entry(context, change, staged: false),
                      ],
                    ),
                  ],
                ),
                _Section(
                  title: l10n.stagedFiles,
                  count: staged.length,
                  expanded: _stagedExpanded,
                  actionLabel: l10n.unstageAllChanges,
                  onAction: staged.isEmpty
                      ? null
                      : () => context.read<RepositoryBloc>().add(
                          const AllFilesUnstaged(),
                        ),
                  onToggle: () =>
                      setState(() => _stagedExpanded = !_stagedExpanded),
                  children: [
                    ChangedFilesList(
                      mode: _mode,
                      entries: [
                        for (final change in staged)
                          _entry(context, change, staged: true),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  ChangedFileEntry _entry(
    BuildContext context,
    FileChange change, {
    required bool staged,
  }) {
    final diff = _findDiff(
      staged ? widget.tab.stagedDiff : widget.tab.unstagedDiff,
      change,
    );
    return ChangedFileEntry(
      path: change.path,
      oldPath: change.oldPath,
      type: change.type,
      insertions: change.conflicted ? 0 : (diff?.insertions ?? 0),
      deletions: change.conflicted ? 0 : (diff?.deletions ?? 0),
      conflicted: change.conflicted,
      onTap: diff == null
          ? null
          : () => widget.onOpenFile(
              OpenFileRequest(
                repositoryPath: widget.tab.repository.path,
                file: diff,
                source: staged
                    ? FileDiffSource.staged
                    : FileDiffSource.unstaged,
              ),
            ),
      trailing: change.conflicted
          ? null
          : _stageAction(context, change, staged: staged),
    );
  }

  Widget _stageAction(
    BuildContext context,
    FileChange change, {
    required bool staged,
  }) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: staged ? l10n.unstageFileTooltip : l10n.stageFileTooltip,
      onPressed: () => context.read<RepositoryBloc>().add(
        staged ? FilesUnstaged([change.path]) : FilesStaged([change.path]),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      visualDensity: VisualDensity.compact,
      iconSize: 14,
      color: AppColors.primary,
      icon: Icon(staged ? Icons.remove : Icons.add),
    );
  }

  static DiffFile? _findDiff(DiffResult diff, FileChange change) {
    for (final file in diff.files) {
      if (file.path == change.path) {
        return file;
      }
      if (file.oldPath != null && file.oldPath == change.path) {
        return file;
      }
      if (change.oldPath != null &&
          (file.path == change.oldPath || file.oldPath == change.oldPath)) {
        return file;
      }
    }
    return null;
  }
}

/// Compact expandable section header plus its children.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 4),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      l10n.branchSectionTitle(title, count),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                      child: Text(actionLabel!),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...children,
        const Divider(height: 1),
      ],
    );
  }
}
