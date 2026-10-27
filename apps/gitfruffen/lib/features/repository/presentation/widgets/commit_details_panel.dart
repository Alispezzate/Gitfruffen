import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/changed_files_list.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Right panel showing the selected commit and its changed files.
class CommitDetailsPanel extends StatefulWidget {
  const CommitDetailsPanel({
    required this.tab,
    required this.onOpenFile,
    super.key,
  });

  final RepositoryTab tab;
  final ValueChanged<OpenFileRequest> onOpenFile;

  @override
  State<CommitDetailsPanel> createState() => _CommitDetailsPanelState();
}

class _CommitDetailsPanelState extends State<CommitDetailsPanel> {
  FileViewMode _mode = FileViewMode.path;

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final l10n = AppLocalizations.of(context);
    final oid = tab.selectedCommitOid;
    if (oid == null) {
      return AppEmptyState(
        icon: Icons.account_tree_outlined,
        title: l10n.commitDetailsEmpty,
        message: l10n.commitDetailsHint,
      );
    }

    final commit = _findCommit(tab, oid);
    return Column(
      children: [
        _Header(oid: oid, commit: commit),
        const Divider(height: 1),
        Expanded(child: _body(context, tab, oid, commit)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    RepositoryTab tab,
    GitOid oid,
    Commit? commit,
  ) {
    final l10n = AppLocalizations.of(context);
    if (tab.isLoadingCommitDiff) {
      return const AppLoading();
    }
    if (tab.diffFailure != null) {
      return AppErrorView(
        message: tab.diffFailure!.message,
        onRetry: () => context.read<RepositoryBloc>().add(CommitSelected(oid)),
      );
    }

    final diff = tab.commitDiff;
    if (commit == null || diff == null) {
      return Center(child: Text(l10n.commitDetailsEmpty));
    }

    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.fileChangesSummary(diff.files.length)),
                    TextSpan(
                      text: '  +${diff.insertions}',
                      style: const TextStyle(color: AppColors.added),
                    ),
                    TextSpan(
                      text: '  -${diff.deletions}',
                      style: const TextStyle(color: AppColors.deleted),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FileViewModeToggle(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (diff.files.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.diffNoChanges, style: theme.textTheme.bodySmall),
          )
        else
          ChangedFilesList(
            mode: _mode,
            entries: [
              for (final file in diff.files)
                ChangedFileEntry(
                  path: file.path,
                  oldPath: file.oldPath,
                  type: file.changeType,
                  insertions: file.insertions,
                  deletions: file.deletions,
                  onTap: () => widget.onOpenFile(
                    OpenFileRequest(
                      repositoryPath: tab.repository.path,
                      file: file,
                      source: FileDiffSource.commit,
                      commitOid: oid,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static Commit? _findCommit(RepositoryTab tab, GitOid oid) {
    for (final commit in tab.graph) {
      if (commit.oid == oid) {
        return commit;
      }
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.oid, this.commit});

  final GitOid oid;
  final Commit? commit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final commit = this.commit;
    final summary = commit?.summary ?? oid.short;
    final author = commit == null
        ? '-'
        : '${commit.author.name} <${commit.author.email}>';
    final date = commit == null
        ? '-'
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(commit.author.when.toLocal());
    final parent = commit == null || commit.parentOids.isEmpty
        ? '-'
        : commit.parentOids.first.short;
    final committer = commit?.committer;
    final committerLabel =
        committer != null &&
            (committer.name != commit!.author.name ||
                committer.email != commit.author.email)
        ? '${l10n.commitCommitterLabel}: '
              '${committer.name} <${committer.email}>'
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: l10n.backToChanges,
            onPressed: () => context.read<RepositoryBloc>().add(
              const CommitSelectionCleared(),
            ),
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${oid.short} · $author',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (committerLabel != null)
                  Text(
                    committerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 1),
                Text(
                  '$date · ${l10n.commitParentsLabel}: $parent',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
