import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_shell.dart';
import '../../features/branches/presentation/branches_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/repository/presentation/repository_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/welcome/presentation/welcome_page.dart';

/// Declarative routing table.
///
/// Every feature lives under a `ShellRoute` so the [AppShell] (sidebar) stays
/// mounted while the inner page swaps.
abstract final class AppRouter {
  static GoRouter create() => GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/repository',
            builder: (context, state) => const RepositoryPage(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/branches',
            builder: (context, state) => const BranchesPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
}
