import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/file_change_tile.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Right panel of the repository workspace.
///
/// Shows the working tree changes split into staged and unstaged sections and
/// the commit prompt that creates a commit from the index.
class ChangesPanel extends StatefulWidget {
  const ChangesPanel({required this.tab, super.key});

  final RepositoryTab tab;

  @override
  State<ChangesPanel> createState() => _ChangesPanelState();
}

class _ChangesPanelState extends State<ChangesPanel> {
  final TextEditingController _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _message.text.trim();
    if (message.isEmpty) {
      return;
    }
    context.read<RepositoryBloc>().add(CommitSubmitted(message));
    _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final changes = widget.tab.status.changes;
    final staged = changes.where((c) => c.staged).toList();
    final unstaged = changes.where((c) => !c.staged || c.unstaged).toList();
    final isBusy = context.select<RepositoryBloc, bool>(
      (bloc) => bloc.state.isBusy,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: changes.isEmpty
              ? AppEmptyState(
                  icon: Icons.check_circle_outline,
                  title: l10n.workingTreeClean,
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _ChangeSection(
                      title: l10n.stagedLabel,
                      changes: staged,
                      actionLabel: l10n.unstageAllButton,
                      onAction: staged.isEmpty
                          ? null
                          : () => context.read<RepositoryBloc>().add(
                              const AllFilesUnstaged(),
                            ),
                      onToggle: (change) => context.read<RepositoryBloc>().add(
                        FilesUnstaged([change.path]),
                      ),
                      toggleIcon: Icons.remove,
                      toggleTooltip: l10n.unstageFileTooltip,
                    ),
                    _ChangeSection(
                      title: l10n.unstagedLabel,
                      changes: unstaged,
                      actionLabel: l10n.stageAllButton,
                      onAction: unstaged.isEmpty
                          ? null
                          : () => context.read<RepositoryBloc>().add(
                              const AllFilesStaged(),
                            ),
                      onToggle: (change) => context.read<RepositoryBloc>().add(
                        FilesStaged([change.path]),
                      ),
                      toggleIcon: Icons.add,
                      toggleTooltip: l10n.stageFileTooltip,
                    ),
                  ],
                ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _message,
                minLines: 2,
                maxLines: 5,
                enabled: !isBusy,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.commitMessageHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: (!isBusy && staged.isNotEmpty) ? _submit : null,
                icon: const Icon(Icons.check, size: 18),
                label: Text(l10n.commitButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangeSection extends StatelessWidget {
  const _ChangeSection({
    required this.title,
    required this.changes,
    required this.actionLabel,
    required this.onAction,
    required this.onToggle,
    required this.toggleIcon,
    required this.toggleTooltip,
  });

  final String title;
  final List<FileChange> changes;
  final String actionLabel;
  final VoidCallback? onAction;
  final ValueChanged<FileChange> onToggle;
  final IconData toggleIcon;
  final String toggleTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.branchSectionTitle(title, changes.length),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
        if (changes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('-', style: theme.textTheme.bodySmall),
          )
        else
          for (final change in changes)
            Row(
              children: [
                Expanded(child: FileChangeTile(change: change)),
                IconButton(
                  tooltip: toggleTooltip,
                  onPressed: () => onToggle(change),
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  color: AppColors.primary,
                  icon: Icon(toggleIcon),
                ),
              ],
            ),
      ],
    );
  }
}
