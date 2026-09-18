import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Toolbar above the repository workspace.
///
/// Hosts the primary repository actions: push, pull, create branch, stash,
/// undo and redo.
class RepositoryToolbar extends StatelessWidget {
  const RepositoryToolbar({required this.tab, super.key});

  final RepositoryTab tab;

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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.arrow_upward,
            label: l10n.pushTooltip,
            enabled: !isBusy,
            onPressed: () =>
                context.read<RepositoryBloc>().add(const RepositoryPushed()),
          ),
          _ToolbarButton(
            icon: Icons.arrow_downward,
            label: l10n.pullTooltip,
            enabled: !isBusy,
            onPressed: () =>
                context.read<RepositoryBloc>().add(const RepositoryPulled()),
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.call_split_outlined,
            label: l10n.createBranchTooltip,
            enabled: !isBusy,
            onPressed: () => _promptBranch(context),
          ),
          _ToolbarButton(
            icon: Icons.inventory_2_outlined,
            label: l10n.stashTooltip,
            enabled: !isBusy,
            onPressed: () => _promptStash(context),
          ),
          const _ToolbarDivider(),
          _ToolbarButton(
            icon: Icons.undo,
            label: l10n.undoTooltip,
            enabled: !isBusy && canUndo,
            onPressed: () => _confirmUndo(context),
          ),
          _ToolbarButton(
            icon: Icons.redo,
            label: l10n.redoTooltip,
            enabled: !isBusy && canRedo,
            onPressed: () => _confirmRedo(context),
          ),
          const Spacer(),
          if (isBusy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
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

  Future<void> _confirmUndo(BuildContext context) => _confirm(
    context,
    title: AppLocalizations.of(context).undoDialogTitle,
    message: AppLocalizations.of(context).undoDialogMessage,
    onConfirm: () => context.read<RepositoryBloc>().add(const UndoRequested()),
  );

  Future<void> _confirmRedo(BuildContext context) => _confirm(
    context,
    title: AppLocalizations.of(context).redoDialogTitle,
    message: AppLocalizations.of(context).redoDialogMessage,
    onConfirm: () => context.read<RepositoryBloc>().add(const RedoRequested()),
  );

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      onConfirm();
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      splashRadius: AppTheme.radius + 8,
    ),
  );
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 22,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: Theme.of(context).dividerColor,
  );
}
