import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_bloc.dart';

/// Application settings: theme mode, recent repositories and engine info.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            _Section(
              title: 'Appearance',
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {state.themeMode},
                onSelectionChanged: (selection) => context
                    .read<SettingsBloc>()
                    .add(ThemeModeChanged(selection.first)),
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Recent repositories',
              child: state.recentRepositories.isEmpty
                  ? const Text('No recent repositories.')
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
              title: 'Git engine',
              child: Text('libgit2: ${state.engineVersion}'),
            ),
          ],
        ),
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
