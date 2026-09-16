import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../features/repository/bloc/repository_bloc.dart';
import '../../features/repository/bloc/repository_state.dart';

/// Primary navigation rail shown on every screen.
///
/// The destination list is data-driven so adding a feature is a one-line change.
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  static const _destinations = <_Destination>[
    _Destination('/repository', Icons.dashboard_outlined, 'Repository'),
    _Destination('/history', Icons.account_tree_outlined, 'History'),
    _Destination('/branches', Icons.call_split_outlined, 'Branches'),
    _Destination('/settings', Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    return Container(
      width: AppTheme.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RepositoryHeader(),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 8),
          for (final destination in _destinations)
            _SidebarTile(
              destination: destination,
              selected: location.startsWith(destination.route),
            ),
          const Spacer(),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.route, this.icon, this.label);

  final String route;
  final IconData icon;
  final String label;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.destination, required this.selected});

  final _Destination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => context.go(destination.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  destination.icon,
                  size: 18,
                  color: selected
                      ? AppColors.primary
                      : theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: selected
                        ? AppColors.primary
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryHeader extends StatelessWidget {
  const _RepositoryHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RepositoryBloc, RepositoryState>(
      buildWhen: (prev, next) => prev.runtimeType != next.runtimeType,
      builder: (context, state) {
        final name = switch (state) {
          RepositoryReady(:final repository) => repository.name,
          _ => 'No repository',
        };
        final branch = switch (state) {
          RepositoryReady(:final status) => status.currentBranchName ?? '-',
          _ => '-',
        };

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.account_tree,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      branch,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Gitfruffen 0.1.0', style: theme.textTheme.bodySmall),
    );
  }
}
