import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Compact bottom bar summarising the active repository.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RepositoryBloc, RepositoryState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final l10n = AppLocalizations.of(context);
          final tab = state.active;

          return Container(
            height: AppTheme.statusBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: tab == null
                      ? Row(
                          children: [
                            _StatusItem(label: l10n.noRepository),
                            const Spacer(),
                            _StatusItem(label: l10n.appVersion),
                          ],
                        )
                      : _ActiveStatus(tab: tab),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l10n.navSettings,
                  onPressed: () => context.go('/settings'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 22,
                    height: 22,
                  ),
                  iconSize: 14,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          );
        },
      );
}

class _ActiveStatus extends StatelessWidget {
  const _ActiveStatus({required this.tab});

  final RepositoryTab tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    var ahead = 0;
    var behind = 0;
    for (final branch in tab.localBranches) {
      if (branch.isHead) {
        ahead = branch.ahead;
        behind = branch.behind;
        break;
      }
    }

    return Row(
      children: [
        _StatusItem(
          icon: Icons.call_split_outlined,
          label: tab.status.currentBranchName ?? '-',
        ),
        if (ahead > 0 || behind > 0) ...[
          const SizedBox(width: 12),
          _StatusItem(label: l10n.branchAheadBehind(ahead, behind)),
        ],
        const Spacer(),
        _StatusItem(
          dotColor: AppColors.added,
          label: '${l10n.stagedLabel} ${tab.status.stagedCount}',
        ),
        const SizedBox(width: 12),
        _StatusItem(
          dotColor: AppColors.modified,
          label: '${l10n.unstagedLabel} ${tab.status.unstagedCount}',
        ),
        if (tab.status.conflictedCount > 0) ...[
          const SizedBox(width: 12),
          _StatusItem(
            dotColor: AppColors.conflicted,
            label: '${l10n.conflictedLabel} ${tab.status.conflictedCount}',
          ),
        ],
        const SizedBox(width: 12),
        Flexible(
          child: _StatusItem(
            icon: Icons.folder_outlined,
            label: tab.repository.path,
            maxWidth: 360,
          ),
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.label,
    this.icon,
    this.dotColor,
    this.maxWidth,
  });

  final String label;
  final IconData? icon;
  final Color? dotColor;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final text = Text(
      label,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final icon?) Icon(icon, size: 13, color: style?.color),
        if (dotColor case final color?)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 4),
        if (maxWidth case final maxWidth?)
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: text,
            ),
          )
        else
          text,
      ],
    );
  }
}
