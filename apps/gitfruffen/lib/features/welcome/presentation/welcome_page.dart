import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/dialogs/repository_dialogs.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Landing screen: open an existing repository, clone one, or pick a recent.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: BlocListener<RepositoryBloc, RepositoryState>(
        listenWhen: (prev, next) =>
            (next.activePath != null && prev.activePath != next.activePath) ||
            next is RepositoryError,
        listener: (context, state) {
          if (state is RepositoryError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.failure.message)));
            return;
          }
          context.go('/repository');
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                        ),
                        child: const Icon(
                          Icons.account_tree,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeTagline,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 40),
                  const _RepositoryActionsCard(),
                  const SizedBox(height: 24),
                  const _RecentRepositories(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepositoryActionsCard extends StatelessWidget {
  const _RepositoryActionsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: DefaultTabController(
        length: 3,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: theme.textTheme.bodySmall?.color,
                tabs: [
                  Tab(text: l10n.openButton),
                  Tab(text: l10n.cloneButton),
                  Tab(text: l10n.newRepositoryTab),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: TabBarView(
                  children: [
                    _ActionPane(
                      title: l10n.openRepositoryTitle,
                      subtitle: l10n.openRepositorySubtitle,
                      buttonLabel: l10n.browseButton,
                      icon: Icons.folder_open,
                      onPressed: () => openRepositoryDialog(context),
                    ),
                    _ActionPane(
                      title: l10n.cloneDialogTitle,
                      subtitle: l10n.cloneTabSubtitle,
                      buttonLabel: l10n.cloneButton,
                      icon: Icons.download_outlined,
                      onPressed: () => showCloneRepositoryDialog(context),
                    ),
                    _ActionPane(
                      title: l10n.newRepositoryDialogTitle,
                      subtitle: l10n.newRepositorySubtitle,
                      buttonLabel: l10n.newRepositoryConfirmButton,
                      icon: Icons.create_new_folder_outlined,
                      onPressed: () => showNewRepositoryDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPane extends StatelessWidget {
  const _ActionPane({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodySmall),
        const Spacer(),
        FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _RecentRepositories extends StatelessWidget {
  const _RecentRepositories();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recents = context.select<SettingsBloc, List<String>>(
      (bloc) => bloc.state.recentRepositories,
    );

    if (recents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).recentTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final path in recents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.history),
            title: Text(path, overflow: TextOverflow.ellipsis),
            onTap: () =>
                context.read<RepositoryBloc>().add(RepositoryOpened(path)),
          ),
      ],
    );
  }
}
