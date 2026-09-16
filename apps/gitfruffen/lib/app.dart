import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/dependency_injector.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/bloc/settings_bloc.dart';

/// Root widget: wires the Pine dependency graph above the router.
class App extends StatelessWidget {
  const App({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) =>
      DependencyInjector(preferences: preferences, child: const _AppView());
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  final GoRouter _router = AppRouter.create();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) => MaterialApp.router(
          title: 'Gitfruffen',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          routerConfig: _router,
        ),
      );
}
