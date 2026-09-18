import 'package:flutter/material.dart';
import 'package:gitfruffen/core/widgets/app_shell.dart';
import 'package:gitfruffen/features/repository/presentation/repository_page.dart';
import 'package:gitfruffen/features/settings/presentation/settings_page.dart';
import 'package:gitfruffen/features/welcome/presentation/welcome_page.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

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
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).routeNotFound(state.uri.toString()),
        ),
      ),
    ),
  );
}
