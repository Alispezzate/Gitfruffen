import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/file_change_tile.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Working-tree overview for the open repository.
class RepositoryPage extends StatelessWidget {
  const RepositoryPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RepositoryBloc, RepositoryState>(
    buildWhen: (previous, next) =>
        previous.active != next.active ||
        previous.runtimeType != next.runtimeType,
    builder: (context, state) {
      final active = state.active;
      final l10n = AppLocalizations.of(context);
      if (active == null) {
        return switch (state) {
          RepositoryInitial() => AppEmptyState(
            icon: Icons.folder_off_outlined,
            title: l10n.emptyNoRepository,
            message: l10n.emptyNoRepositoryMessage,
          ),
          RepositoryLoading() => AppLoading(message: l10n.openingRepository),
          RepositoryError(:final failure) => AppErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<RepositoryBloc>().add(const RepositoryRefreshed()),
          ),
          RepositoryReady() => AppEmptyState(
            icon: Icons.folder_off_outlined,
            title: l10n.emptyNoRepository,
          ),
        };
      }
      return _StatusView(repository: active.repository, status: active.status);
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
    final l10n = AppLocalizations.of(context);
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
                tooltip: l10n.refreshTooltip,
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
                label: l10n.stagedLabel,
                value: status.stagedCount,
                color: AppColors.added,
              ),
              _StatChip(
                label: l10n.unstagedLabel,
                value: status.unstagedCount,
                color: AppColors.modified,
              ),
              _StatChip(
                label: l10n.conflictedLabel,
                value: status.conflictedCount,
                color: AppColors.conflicted,
              ),
              _StatChip(
                label: l10n.totalLabel,
                value: changes.length,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.changesTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: status.isClean
                ? AppEmptyState(
                    icon: Icons.check_circle_outline,
                    title: l10n.workingTreeClean,
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
