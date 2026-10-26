import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/dialogs/repository_dialogs.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Horizontal strip of open repositories shown above the feature content.
///
/// Each tab switches the active repository; the trailing add menu opens, clones
/// or initialises a repository without leaving the current screen.
class RepositoryTabs extends StatelessWidget {
  const RepositoryTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = context.select<RepositoryBloc, List<RepositoryTab>>(
      (bloc) => bloc.state.tabs,
    );
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final activePath = context.select<RepositoryBloc, String?>(
      (bloc) => bloc.state.activePath,
    );

    return Container(
      height: AppTheme.tabHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return _RepositoryTabTile(
                  tab: tab,
                  selected: tab.repository.path == activePath,
                  onSelect: () {
                    context.read<RepositoryBloc>().add(
                      RepositoryTabSelected(tab.repository.path),
                    );
                    context.go('/repository');
                  },
                  onClose: () => context.read<RepositoryBloc>().add(
                    RepositoryTabClosed(tab.repository.path),
                  ),
                );
              },
            ),
          ),
          const _AddRepositoryButton(),
        ],
      ),
    );
  }
}

class _RepositoryTabTile extends StatelessWidget {
  const _RepositoryTabTile({
    required this.tab,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  final RepositoryTab tab;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changes = tab.status.changes.length;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: theme.dividerColor),
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 15,
                color: selected ? AppColors.primary : theme.iconTheme.color,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  tab.repository.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.primary : null,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (changes > 0) ...[
                const SizedBox(width: 8),
                _ChangeBadge(count: changes),
              ],
              const SizedBox(width: 4),
              IconButton(
                tooltip: AppLocalizations.of(context).closeRepositoryTooltip,
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                iconSize: 14,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: AppColors.modified.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      '$count',
      style: const TextStyle(fontSize: 10, color: AppColors.modified),
    ),
  );
}

enum _AddRepositoryAction { open, clone, create }

class _AddRepositoryButton extends StatelessWidget {
  const _AddRepositoryButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<_AddRepositoryAction>(
        tooltip: l10n.openRepositoryTooltip,
        icon: const Icon(Icons.add, size: 18),
        padding: EdgeInsets.zero,
        onSelected: (action) => switch (action) {
          _AddRepositoryAction.open => openRepositoryDialog(context),
          _AddRepositoryAction.clone => showCloneRepositoryDialog(context),
          _AddRepositoryAction.create => showNewRepositoryDialog(context),
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _AddRepositoryAction.open,
            child: Text(l10n.openButton),
          ),
          PopupMenuItem(
            value: _AddRepositoryAction.clone,
            child: Text(l10n.cloneButton),
          ),
          PopupMenuItem(
            value: _AddRepositoryAction.create,
            child: Text(l10n.newRepositoryMenuItem),
          ),
        ],
      ),
    );
  }
}
