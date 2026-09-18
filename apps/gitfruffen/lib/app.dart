import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/di/dependency_injector.dart';
import 'package:gitfruffen/core/router/app_router.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Root widget: wires the Pine dependency graph above the router.
class App extends StatelessWidget {
  const App({required this.preferences, super.key});

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
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.languageCode == null
              ? null
              : Locale(settings.languageCode!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      );
}
