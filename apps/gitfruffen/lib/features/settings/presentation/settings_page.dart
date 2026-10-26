import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Application settings: appearance, Git and about sections in two columns.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _SettingsSection { appearance, git, about }

class _SettingsPageState extends State<SettingsPage> {
  _SettingsSection _section = _SettingsSection.appearance;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final content = switch (_section) {
            _SettingsSection.appearance => _appearance(l10n, state),
            _SettingsSection.git => _git(l10n, state),
            _SettingsSection.about => _about(l10n),
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.settingsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: ListView(
                        children: [
                          _NavTile(
                            label: l10n.settingsAppearance,
                            icon: Icons.palette_outlined,
                            selected: _section == _SettingsSection.appearance,
                            onTap: () => setState(
                              () => _section = _SettingsSection.appearance,
                            ),
                          ),
                          _NavTile(
                            label: l10n.settingsGit,
                            icon: Icons.account_tree_outlined,
                            selected: _section == _SettingsSection.git,
                            onTap: () =>
                                setState(() => _section = _SettingsSection.git),
                          ),
                          _NavTile(
                            label: l10n.settingsAbout,
                            icon: Icons.info_outline,
                            selected: _section == _SettingsSection.about,
                            onTap: () => setState(
                              () => _section = _SettingsSection.about,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: content,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );

  List<Widget> _appearance(AppLocalizations l10n, SettingsState state) => [
    _Section(
      title: l10n.settingsAppearance,
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
          ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
          ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
        ],
        selected: {state.themeMode},
        onSelectionChanged: (selection) =>
            context.read<SettingsBloc>().add(ThemeModeChanged(selection.first)),
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
  ];

  List<Widget> _git(AppLocalizations l10n, SettingsState state) => [
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
  ];

  List<Widget> _about(AppLocalizations l10n) => [
    _Section(
      title: l10n.appVersion,
      child: Text(
        l10n.settingsAboutDescription,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  ];
}

const String _systemLanguage = 'system';

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    selected: selected,
    selectedColor: AppColors.primary,
    selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radius),
    ),
    onTap: onTap,
  );
}

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
