import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/widgets/app_shortcuts.dart';
import 'package:gitfruffen/core/widgets/repository_tabs.dart';
import 'package:gitfruffen/core/widgets/status_bar.dart';
import 'package:gitfruffen/core/widgets/workspace_menu_bar.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:go_router/go_router.dart';

/// Persistent shell hosting the application menu, the repository tab strip, the
/// active feature page and the [StatusBar].
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocListener<RepositoryBloc, RepositoryState>(
      listenWhen: (previous, next) =>
          next is RepositoryInitial ||
          (next is RepositoryReady && previous is! RepositoryReady) ||
          (next is RepositoryReady && next.failure != null),
      listener: (context, state) {
        if (state is RepositoryInitial) {
          context.go('/welcome');
          return;
        }
        final ready = state as RepositoryReady;
        if (ready.failure case final failure?) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
          return;
        }
        context.read<SettingsBloc>().add(const SettingsLoaded());
      },
      child: AppShortcuts(
        child: Column(
          children: [
            const WorkspaceMenuBar(),
            const RepositoryTabs(),
            Expanded(child: child),
            const StatusBar(),
          ],
        ),
      ),
    ),
  );
}
