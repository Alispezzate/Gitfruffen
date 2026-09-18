import 'package:flutter/material.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Renders a single working-tree change with its staging state.
class FileChangeTile extends StatelessWidget {
  const FileChangeTile({required this.change, super.key});

  final FileChange change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _colorFor(change.type);

    return ListTile(
      leading: Icon(_iconFor(change.type), size: 18, color: color),
      title: Text(
        change.path,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: change.oldPath == null
          ? null
          : Text(
              l10n.fileChangeFrom(change.oldPath!),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (change.staged)
            _Badge(label: l10n.badgeStaged, color: AppColors.added),
          if (change.unstaged) ...[
            const SizedBox(width: 6),
            _Badge(label: l10n.badgeUnstaged, color: AppColors.modified),
          ],
          if (change.conflicted) ...[
            const SizedBox(width: 6),
            _Badge(label: l10n.badgeConflict, color: AppColors.conflicted),
          ],
        ],
      ),
    );
  }

  Color _colorFor(FileChangeType type) => switch (type) {
    FileChangeType.added => AppColors.added,
    FileChangeType.modified => AppColors.modified,
    FileChangeType.deleted => AppColors.deleted,
    FileChangeType.renamed => AppColors.primary,
    FileChangeType.untracked => AppColors.untracked,
    FileChangeType.conflicted => AppColors.conflicted,
  };

  IconData _iconFor(FileChangeType type) => switch (type) {
    FileChangeType.added => Icons.add_circle_outline,
    FileChangeType.modified => Icons.edit_outlined,
    FileChangeType.deleted => Icons.remove_circle_outline,
    FileChangeType.renamed => Icons.drive_file_rename_outline,
    FileChangeType.untracked => Icons.fiber_new_outlined,
    FileChangeType.conflicted => Icons.warning_amber_outlined,
  };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: color)),
  );
}
