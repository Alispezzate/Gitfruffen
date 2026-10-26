import 'package:flutter/material.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Unified diff of a single file with line numbers and change tinting.
class FileDiffView extends StatelessWidget {
  const FileDiffView({required this.file, required this.onBack, super.key});

  final DiffFile file;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.closeFileView,
                onPressed: onBack,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  file.path,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '+${file.insertions}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.added,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '-${file.deletions}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.deleted,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _body(theme, l10n)),
      ],
    );
  }

  Widget _body(ThemeData theme, AppLocalizations l10n) {
    if (file.isBinary) {
      return Center(child: Text(l10n.diffBinaryFile));
    }
    if (file.hunks.isEmpty) {
      return Center(child: Text(l10n.diffNoChanges));
    }

    final mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: theme.textTheme.bodyMedium?.color,
    );
    final number = mono.copyWith(
      fontSize: 11,
      color: theme.textTheme.bodySmall?.color,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final hunk in file.hunks) ...[
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              hunk.header,
              style: mono.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final line in hunk.lines)
            Container(
              color: switch (line.kind) {
                DiffLineKind.added => AppColors.added.withValues(alpha: 0.12),
                DiffLineKind.removed => AppColors.deleted.withValues(
                  alpha: 0.12,
                ),
                DiffLineKind.context => null,
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _number(line.oldLine, number, 40),
                  _number(line.newLine, number, 40),
                  SizedBox(
                    width: 16,
                    child: Text(
                      switch (line.kind) {
                        DiffLineKind.added => '+',
                        DiffLineKind.removed => '-',
                        DiffLineKind.context => ' ',
                      },
                      style: mono,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.content.isEmpty ? ' ' : line.content,
                      style: mono,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _number(int? value, TextStyle style, double width) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        value?.toString() ?? '-',
        style: style,
        textAlign: TextAlign.right,
      ),
    ),
  );
}
