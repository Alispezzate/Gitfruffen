import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/widgets/repository_tabs.dart';
import 'package:gitfruffen/core/widgets/sidebar.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:go_router/go_router.dart';

/// Persistent shell hosting the repository tab strip, the [Sidebar] and the
/// active feature page.
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
      child: Column(
        children: [
          const RepositoryTabs(),
          Expanded(
            child: Row(
              children: [
                const Sidebar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
