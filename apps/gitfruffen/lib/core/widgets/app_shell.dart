import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/repository/bloc/repository_bloc.dart';
import '../../features/repository/bloc/repository_state.dart';
import '../../features/settings/bloc/settings_bloc.dart';
import 'sidebar.dart';

/// Persistent shell hosting the [Sidebar] and the active feature page.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocListener<RepositoryBloc, RepositoryState>(
      listenWhen: (previous, next) =>
          next is RepositoryReady && previous is! RepositoryReady,
      listener: (context, state) =>
          context.read<SettingsBloc>().add(const SettingsLoaded()),
      child: Row(
        children: [
          const Sidebar(),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
