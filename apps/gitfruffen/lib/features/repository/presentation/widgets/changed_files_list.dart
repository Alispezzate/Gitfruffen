import 'package:flutter/material.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// How changed files are grouped in a list.
enum FileViewMode { path, tree }

/// A single file rendered by [ChangedFilesList].
class ChangedFileEntry {
  const ChangedFileEntry({
    required this.path,
    required this.type,
    required this.insertions,
    required this.deletions,
    this.oldPath,
    this.conflicted = false,
    this.onTap,
    this.trailing,
  });

  final String path;
  final String? oldPath;
  final FileChangeType type;
  final int insertions;
  final int deletions;
  final bool conflicted;
  final VoidCallback? onTap;
  final Widget? trailing;
}

/// Compact Path / Tree switch used by the changes and commit panels.
class FileViewModeToggle extends StatelessWidget {
  const FileViewModeToggle({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final FileViewMode mode;
  final ValueChanged<FileViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(context, l10n.pathView, FileViewMode.path),
        _button(context, l10n.treeView, FileViewMode.tree),
      ],
    );
  }

  Widget _button(BuildContext context, String label, FileViewMode value) {
    final theme = Theme.of(context);
    final selected = mode == value;
    return TextButton(
      onPressed: () => onChanged(value),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 24),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: selected
            ? theme.colorScheme.primary
            : theme.textTheme.bodySmall?.color,
        backgroundColor: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: theme.textTheme.bodySmall?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Non-scrolling list of changed files, either flat or grouped by directory.
class ChangedFilesList extends StatelessWidget {
  const ChangedFilesList({
    required this.entries,
    required this.mode,
    super.key,
  });

  final List<ChangedFileEntry> entries;
  final FileViewMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == FileViewMode.path) {
      final sorted = [...entries]..sort((a, b) => a.path.compareTo(b.path));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [for (final entry in sorted) _row(context, entry)],
      );
    }

    final groups = <String, List<ChangedFileEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(_directoryOf(entry.path), () => []).add(entry);
    }
    final directories = groups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final directory in directories) ...[
          _folder(context, directory),
          for (final entry
              in groups[directory]!..sort((a, b) => a.path.compareTo(b.path)))
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _row(context, entry, basename: true),
            ),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    ChangedFileEntry entry, {
    bool basename = false,
  }) {
    final theme = Theme.of(context);
    final name = basename ? entry.path.split('/').last : entry.path;
    final tooltip = entry.oldPath == null
        ? entry.path
        : '${entry.oldPath} -> ${entry.path}';

    return InkWell(
      onTap: entry.onTap,
      child: SizedBox(
        height: 28,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Row(
            children: [
              Icon(
                _iconFor(entry.type),
                size: 14,
                color: _colorFor(entry.type),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Tooltip(
                  message: tooltip,
                  waitDuration: const Duration(milliseconds: 600),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              if (!entry.conflicted) ...[
                Text(
                  '+${entry.insertions}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.added,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '-${entry.deletions}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.deleted,
                  ),
                ),
              ],
              if (entry.trailing != null) entry.trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _folder(BuildContext context, String directory) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 22,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                directory.isEmpty ? '.' : directory,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _directoryOf(String path) {
    final index = path.lastIndexOf('/');
    return index == -1 ? '' : path.substring(0, index);
  }

  static Color _colorFor(FileChangeType type) => switch (type) {
    FileChangeType.added => AppColors.added,
    FileChangeType.modified => AppColors.modified,
    FileChangeType.deleted => AppColors.deleted,
    FileChangeType.renamed => AppColors.primary,
    FileChangeType.untracked => AppColors.untracked,
    FileChangeType.conflicted => AppColors.conflicted,
  };

  static IconData _iconFor(FileChangeType type) => switch (type) {
    FileChangeType.added => Icons.add_circle_outline,
    FileChangeType.modified => Icons.edit_outlined,
    FileChangeType.deleted => Icons.remove_circle_outline,
    FileChangeType.renamed => Icons.drive_file_rename_outline,
    FileChangeType.untracked => Icons.fiber_new_outlined,
    FileChangeType.conflicted => Icons.warning_amber_outlined,
  };
}
