import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Application settings: theme mode, language, recent repositories and engine
/// info.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SettingsBloc, SettingsState>(
    builder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.settingsAppearance,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (selection) => context
                  .read<SettingsBloc>()
                  .add(ThemeModeChanged(selection.first)),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.settingsLanguage,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: _systemLanguage,
                  label: Text(l10n.languageSystem),
                ),
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ButtonSegment(value: 'it', label: Text(l10n.languageItalian)),
              ],
              selected: {state.languageCode ?? _systemLanguage},
              onSelectionChanged: (selection) {
                final code = selection.first;
                context.read<SettingsBloc>().add(
                  LanguageChanged(code == _systemLanguage ? null : code),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.settingsRecentRepositories,
            child: state.recentRepositories.isEmpty
                ? Text(l10n.settingsNoRecentRepositories)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final path in state.recentRepositories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(path),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.settingsGitEngine,
            child: Text(l10n.libgit2Version(state.engineVersion)),
          ),
        ],
      );
    },
  );
}

const String _systemLanguage = 'system';

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      child,
    ],
  );
}
