import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/repository/bloc/repository_bloc.dart';
import '../../features/repository/bloc/repository_event.dart';
import '../../features/repository/bloc/repository_state.dart';
import '../services/file_picker_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Horizontal strip of open repositories shown above the feature content.
///
/// Each tab switches the active repository; the trailing button browses for a
/// new folder without leaving the current screen.
class RepositoryTabs extends StatelessWidget {
  const RepositoryTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = context.select((RepositoryBloc bloc) => bloc.state.tabs);
    if (tabs.isEmpty) return const SizedBox.shrink();

    final activePath = context.select(
      (RepositoryBloc bloc) => bloc.state.activePath,
    );

    return Container(
      height: 40,
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
                  onSelect: () => context.read<RepositoryBloc>().add(
                    RepositoryTabSelected(tab.repository.path),
                  ),
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
          ? AppColors.primary.withValues(alpha: 0.16)
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
                  style: theme.textTheme.bodyLarge?.copyWith(
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
                tooltip: 'Close repository',
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

class _AddRepositoryButton extends StatelessWidget {
  const _AddRepositoryButton();

  Future<void> _browse(BuildContext context) async {
    final picker = context.read<FilePickerService>();
    final path = await picker.pickDirectory(title: 'Open repository');
    if (path == null || !context.mounted) return;
    context.read<RepositoryBloc>().add(RepositoryOpened(path));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Tooltip(
      message: 'Open a repository',
      child: OutlinedButton.icon(
        onPressed: () => _browse(context),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Open'),
      ),
    ),
  );
}
