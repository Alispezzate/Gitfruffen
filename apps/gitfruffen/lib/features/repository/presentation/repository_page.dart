import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../bloc/repository_bloc.dart';
import '../bloc/repository_event.dart';
import '../bloc/repository_state.dart';
import 'widgets/file_change_tile.dart';

/// Working-tree overview for the open repository.
class RepositoryPage extends StatelessWidget {
  const RepositoryPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RepositoryBloc, RepositoryState>(
        builder: (context, state) => switch (state) {
          RepositoryInitial() => const AppEmptyState(
            icon: Icons.folder_off_outlined,
            title: 'No repository open',
            message: 'Open a repository from the welcome screen.',
          ),
          RepositoryLoading() => const AppLoading(message: 'Opening…'),
          RepositoryError(:final failure) => AppErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<RepositoryBloc>().add(const RepositoryRefreshed()),
          ),
          RepositoryReady(:final repository, :final status) => _StatusView(
            repository: repository,
            status: status,
          ),
        },
      );
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.repository, required this.status});

  final GitRepository repository;
  final RepositoryStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changes = status.changes;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repository.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      status.currentBranchName ?? repository.path,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => context.read<RepositoryBloc>().add(
                  const RepositoryRefreshed(),
                ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(
                label: 'Staged',
                value: status.stagedCount,
                color: AppColors.added,
              ),
              _StatChip(
                label: 'Unstaged',
                value: status.unstagedCount,
                color: AppColors.modified,
              ),
              _StatChip(
                label: 'Conflicted',
                value: status.conflictedCount,
                color: AppColors.conflicted,
              ),
              _StatChip(
                label: 'Total',
                value: changes.length,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Changes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: status.isClean
                ? const AppEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'Working tree clean',
                  )
                : Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: changes.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: theme.dividerColor),
                      itemBuilder: (context, index) =>
                          FileChangeTile(change: changes[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
