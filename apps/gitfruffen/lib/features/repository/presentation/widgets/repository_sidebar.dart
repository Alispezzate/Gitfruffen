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
/// Groups the repository refs in collapsible sections: local branches, remote
/// branches, worktrees and tags, filtered by name or path.
class RepositorySidebar extends StatefulWidget {
  const RepositorySidebar({required this.tab, super.key});

  final RepositoryTab tab;

  @override
  State<RepositorySidebar> createState() => _RepositorySidebarState();
}

class _RepositorySidebarState extends State<RepositorySidebar> {
  final TextEditingController _filterController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<T> _filtered<T>(List<T> items, String Function(T item) text) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }
    return items
        .where((item) => text(item).toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tab = widget.tab;
    final localBranches = _filtered(tab.localBranches, (branch) => branch.name);
    final remoteBranches = _filtered(
      tab.remoteBranches,
      (branch) => branch.name,
    );
    final worktrees = _filtered(
      tab.worktrees,
      (worktree) => '${worktree.name} ${worktree.path}',
    );
    final tags = _filtered(tab.tags, (tag) => tag.name);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _filterController,
            onChanged: (value) => setState(() => _query = value),
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: l10n.filterHint,
              prefixIcon: const Icon(Icons.search, size: 16),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              _Section(
                title: l10n.branchLocalSection,
                count: localBranches.length,
                icon: Icons.call_split_outlined,
                expanded: true,
                children: [
                  for (final branch in localBranches)
                    GestureDetector(
                      onSecondaryTapDown: branch.isHead
                          ? null
                          : (details) => _showBranchMenu(
                              context,
                              details.globalPosition,
                              branch,
                            ),
                      child: _BranchTile(
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
                    ),
                ],
              ),
              _Section(
                title: l10n.branchRemoteSection,
                count: remoteBranches.length,
                icon: Icons.cloud_outlined,
                children: [
                  for (final branch in remoteBranches)
                    _BranchTile(branch: branch),
                ],
              ),
              _Section(
                title: l10n.worktreesSection,
                count: worktrees.length,
                icon: Icons.work_outline,
                children: [
                  for (final worktree in worktrees)
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
                count: tags.length,
                icon: Icons.local_offer_outlined,
                children: [for (final tag in tags) _TagTile(tag: tag)],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showBranchMenu(
    BuildContext context,
    Offset position,
    Branch branch,
  ) async {
    if (branch.isHead || branch.isRemote) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem(value: 'checkout', child: Text(l10n.checkoutButton)),
        PopupMenuItem(
          value: 'delete',
          child: Text(l10n.deleteBranchDialogTitle),
        ),
      ],
    );
    if (selected == null || !context.mounted) {
      return;
    }
    if (selected == 'checkout') {
      context.read<RepositoryBloc>().add(BranchCheckedOut(branch.name));
    } else if (selected == 'delete') {
      await _confirmDelete(context, branch);
    }
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
      tilePadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Icon(icon, size: 15),
      title: Text(
        l10n.branchSectionTitle(title, count).toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 4),
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
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        branch.isHead
            ? Icons.check
            : branch.isRemote
            ? Icons.cloud_outlined
            : Icons.call_split_outlined,
        size: 15,
        color: branch.isHead ? AppColors.primary : theme.iconTheme.color,
      ),
      title: Text(
        branch.name,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
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
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        worktree.isMain ? Icons.home_outlined : Icons.work_outline,
        size: 15,
      ),
      title: Text(
        worktree.name,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
      ),
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
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: const Icon(Icons.local_offer_outlined, size: 15),
      title: Text(
        tag.name,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
      ),
      subtitle: Text(tag.targetOid, style: theme.textTheme.bodySmall),
      trailing: tag.isAnnotated
          ? Icon(Icons.label_outline, size: 14, color: theme.iconTheme.color)
          : null,
    );
  }
}
