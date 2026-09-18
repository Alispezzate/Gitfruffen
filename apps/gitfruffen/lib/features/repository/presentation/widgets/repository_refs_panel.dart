import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Left panel of the repository workspace.
///
/// Lists the repository refs grouped in collapsible sections: local branches,
/// remote branches, worktrees and tags.
class RepositoryRefsPanel extends StatelessWidget {
  const RepositoryRefsPanel({required this.tab, super.key});

  final RepositoryTab tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _Section(
          title: l10n.branchLocalSection,
          count: tab.localBranches.length,
          icon: Icons.call_split_outlined,
          expanded: true,
          children: [
            for (final branch in tab.localBranches)
              _BranchTile(
                branch: branch,
                onCheckout: branch.isHead
                    ? null
                    : () => context.read<RepositoryBloc>().add(
                        BranchCheckedOut(branch.name),
                      ),
                onDelete: branch.isHead
                    ? null
                    : () => _confirmDelete(context, branch),
              ),
          ],
        ),
        _Section(
          title: l10n.branchRemoteSection,
          count: tab.remoteBranches.length,
          icon: Icons.cloud_outlined,
          children: [
            for (final branch in tab.remoteBranches)
              _BranchTile(branch: branch),
          ],
        ),
        _Section(
          title: l10n.worktreesSection,
          count: tab.worktrees.length,
          icon: Icons.work_outline,
          children: [
            for (final worktree in tab.worktrees)
              _WorktreeTile(
                worktree: worktree,
                onRemove: worktree.isMain
                    ? null
                    : () => context.read<RepositoryBloc>().add(
                        WorktreeRemoved(worktree.name),
                      ),
              ),
          ],
        ),
        _Section(
          title: l10n.tagsSection,
          count: tab.tags.length,
          icon: Icons.local_offer_outlined,
          children: [for (final tag in tab.tags) _TagTile(tag: tag)],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Branch branch) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteBranchDialogTitle),
        content: Text(l10n.deleteBranchDialogMessage(branch.name)),
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
      context.read<RepositoryBloc>().add(BranchDeleted(branch.name));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.icon,
    required this.children,
    this.expanded = false,
  });

  final String title;
  final int count;
  final IconData icon;
  final List<Widget> children;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ExpansionTile(
      initiallyExpanded: expanded,
      dense: true,
      leading: Icon(icon, size: 16),
      title: Text(
        l10n.branchSectionTitle(title, count),
        style: theme.textTheme.titleMedium,
      ),
      childrenPadding: const EdgeInsets.only(left: 8),
      children: children.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('-', style: theme.textTheme.bodySmall),
              ),
            ]
          : children,
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch, this.onCheckout, this.onDelete});

  final Branch branch;
  final VoidCallback? onCheckout;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(
        branch.isRemote ? Icons.cloud_outlined : Icons.call_split_outlined,
        size: 16,
        color: branch.isHead ? AppColors.primary : theme.iconTheme.color,
      ),
      title: Text(
        branch.name,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: branch.isHead ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: (branch.ahead > 0 || branch.behind > 0)
          ? Text(
              l10n.branchAheadBehind(branch.ahead, branch.behind),
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCheckout != null)
            IconButton(
              tooltip: l10n.checkoutButton,
              onPressed: onCheckout,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              icon: const Icon(Icons.check_circle_outline),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: l10n.deleteBranchTooltip,
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}

class _WorktreeTile extends StatelessWidget {
  const _WorktreeTile({required this.worktree, this.onRemove});

  final WorktreeInfo worktree;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(
        worktree.isMain ? Icons.home_outlined : Icons.work_outline,
        size: 16,
      ),
      title: Text(worktree.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        worktree.path,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (worktree.isLocked)
            Icon(Icons.lock_outline, size: 14, color: theme.iconTheme.color),
          if (onRemove != null)
            IconButton(
              tooltip: l10n.removeWorktreeTooltip,
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: const Icon(Icons.local_offer_outlined, size: 16),
      title: Text(tag.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(tag.targetOid, style: theme.textTheme.bodySmall),
      trailing: tag.isAnnotated
          ? Icon(Icons.label_outline, size: 14, color: theme.iconTheme.color)
          : null,
    );
  }
}
