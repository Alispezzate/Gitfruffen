import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/file_picker_service.dart';
import '../../repository/bloc/repository_bloc.dart';
import '../../repository/bloc/repository_event.dart';
import '../../repository/bloc/repository_state.dart';
import '../../settings/bloc/settings_bloc.dart';

/// Landing screen: open an existing repository, clone one, or pick a recent.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocListener<RepositoryBloc, RepositoryState>(
      listenWhen: (prev, next) => next is RepositoryReady,
      listener: (context, state) => context.go('/repository'),
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
                      'Gitfruffen',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'A fast, native Git client for your desktop.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 40),
                _OpenRepositoryCard(
                  onOpen: (path) => context.read<RepositoryBloc>().add(
                    RepositoryOpened(path),
                  ),
                ),
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

class _OpenRepositoryCard extends StatelessWidget {
  const _OpenRepositoryCard({required this.onOpen});

  final ValueChanged<String> onOpen;

  Future<void> _browse(BuildContext context) async {
    final picker = context.read<FilePickerService>();
    final path = await picker.pickDirectory(title: 'Open repository');
    if (path != null && context.mounted) onOpen(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Open a repository', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Select a local folder containing a Git repository.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _browse(context),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Browse…'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _promptClone(context),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Clone…'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptClone(BuildContext context) async {
    final urlController = TextEditingController();
    final pathController = TextEditingController();
    final bloc = context.read<RepositoryBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clone repository'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Remote URL'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(labelText: 'Local path'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clone'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(
        RepositoryCloned(
          url: urlController.text.trim(),
          localPath: pathController.text.trim(),
        ),
      );
    }
    urlController.dispose();
    pathController.dispose();
  }
}

class _RecentRepositories extends StatelessWidget {
  const _RecentRepositories();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recents = context.select(
      (SettingsBloc bloc) => bloc.state.recentRepositories,
    );

    if (recents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final path in recents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(path, overflow: TextOverflow.ellipsis),
            onTap: () =>
                context.read<RepositoryBloc>().add(RepositoryOpened(path)),
          ),
      ],
    );
  }
}
