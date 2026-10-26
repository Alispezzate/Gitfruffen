import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/core/widgets/workspace_commands.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/dialogs/repository_dialogs.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Header for the repository workspace with breadcrumb and actions.
class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    required this.tab,
    required this.onToggleTerminal,
    this.leadingWidth = AppTheme.sidebarWidth,
    super.key,
  });

  final RepositoryTab tab;
  final VoidCallback onToggleTerminal;
  final double leadingWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isBusy = context.select<RepositoryBloc, bool>(
      (bloc) => bloc.state.isBusy,
    );
    final canUndo = context.select<RepositoryBloc, bool>(
      (bloc) => bloc.canUndo,
    );
    final canRedo = context.select<RepositoryBloc, bool>(
      (bloc) => bloc.canRedo,
    );

    return Container(
      height: AppTheme.workspaceHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: leadingWidth,
            child: _Breadcrumb(tab: tab),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderAction(
                      icon: Icons.undo,
                      label: l10n.undoTooltip,
                      tooltip: l10n.undoTooltip,
                      onPressed: !isBusy && canUndo
                          ? () => confirmRepositoryUndo(context)
                          : null,
                    ),
                    _HeaderAction(
                      icon: Icons.redo,
                      label: l10n.redoTooltip,
                      tooltip: l10n.redoTooltip,
                      onPressed: !isBusy && canRedo
                          ? () => confirmRepositoryRedo(context)
                          : null,
                    ),
                    _HeaderAction(
                      icon: Icons.arrow_downward,
                      label: l10n.pullTooltip,
                      tooltip: l10n.pullTooltip,
                      onPressed: !isBusy
                          ? () => context.read<RepositoryBloc>().add(
                              const RepositoryPulled(),
                            )
                          : null,
                    ),
                    _HeaderAction(
                      icon: Icons.arrow_upward,
                      label: l10n.pushTooltip,
                      tooltip: l10n.pushTooltip,
                      onPressed: !isBusy
                          ? () => context.read<RepositoryBloc>().add(
                              const RepositoryPushed(),
                            )
                          : null,
                    ),
                    _HeaderAction(
                      icon: Icons.call_split_outlined,
                      label: l10n.branchTooltip,
                      tooltip: l10n.createBranchTooltip,
                      onPressed: !isBusy ? () => _promptBranch(context) : null,
                    ),
                    _HeaderAction(
                      icon: Icons.inventory_2_outlined,
                      label: l10n.stashConfirmButton,
                      tooltip: l10n.stashTooltip,
                      onPressed: !isBusy ? () => _promptStash(context) : null,
                    ),
                    _HeaderAction(
                      icon: Icons.unarchive_outlined,
                      label: l10n.popTooltip,
                      tooltip: l10n.popTooltip,
                      onPressed: !isBusy && tab.stashes.isNotEmpty
                          ? () => context.read<RepositoryBloc>().add(
                              const StashPopped(0),
                            )
                          : null,
                    ),
                    _HeaderAction(
                      icon: Icons.terminal,
                      label: l10n.terminalTitle,
                      tooltip: l10n.terminalToggleTooltip,
                      onPressed: onToggleTerminal,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.searchTooltip,
            onPressed: () => showWorkspaceCommandPalette(context),
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<_WorkspaceAction>(
            tooltip: l10n.actionsTooltip,
            icon: const Icon(Icons.more_horiz, size: 18),
            padding: EdgeInsets.zero,
            onSelected: (action) {
              switch (action) {
                case _WorkspaceAction.fetch:
                  context.read<RepositoryBloc>().add(const RepositoryFetched());
                case _WorkspaceAction.refresh:
                  context.read<RepositoryBloc>().add(
                    const RepositoryRefreshed(),
                  );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _WorkspaceAction.fetch,
                child: Text(l10n.fetchTooltip),
              ),
              PopupMenuItem(
                value: _WorkspaceAction.refresh,
                child: Text(l10n.refreshTooltip),
              ),
            ],
          ),
          IconButton(
            tooltip: l10n.navSettings,
            onPressed: () => context.go('/settings'),
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _promptBranch(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createBranchDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.branchNameLabel),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.createBranchConfirmButton),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) {
      return;
    }
    context.read<RepositoryBloc>().add(
      BranchCreated(name: trimmed, checkout: true),
    );
  }

  Future<void> _promptStash(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.stashDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.stashMessageLabel),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.stashConfirmButton),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || !context.mounted) {
      return;
    }
    final trimmed = message.trim();
    context.read<RepositoryBloc>().add(
      StashCreated(trimmed.isEmpty ? null : trimmed),
    );
  }
}

enum _WorkspaceAction { fetch, refresh }

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.tab});

  final RepositoryTab tab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final muted = theme.textTheme.bodySmall?.color;

    return Row(
      children: [
        Icon(Icons.folder_outlined, size: 14, color: muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            tab.repository.name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 14, color: muted),
        ),
        Flexible(
          child: PopupMenuButton<String>(
            tooltip: l10n.checkoutButton,
            enabled: tab.localBranches.isNotEmpty,
            onSelected: (branch) =>
                context.read<RepositoryBloc>().add(BranchCheckedOut(branch)),
            itemBuilder: (context) => [
              for (final branch in tab.localBranches)
                PopupMenuItem(
                  value: branch.name,
                  child: Row(
                    children: [
                      Icon(
                        branch.isHead ? Icons.check : Icons.call_split_outlined,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(branch.name),
                    ],
                  ),
                ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    tab.status.currentBranchName ?? '-',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.expand_more, size: 14, color: muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onPressed == null
        ? theme.disabledColor
        : theme.textTheme.bodyMedium?.color;

    return Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(54, 48),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
