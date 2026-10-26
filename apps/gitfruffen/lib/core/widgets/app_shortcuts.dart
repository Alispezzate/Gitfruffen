import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/widgets/command_palette.dart';
import 'package:gitfruffen/core/widgets/workspace_commands.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Global keyboard shortcuts for repository tabs and the command palette.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    void closeActive() {
      final path = context.read<RepositoryBloc>().state.activePath;
      if (path == null) {
        return;
      }
      context.read<RepositoryBloc>().add(RepositoryTabClosed(path));
    }

    void cycleTab() {
      final state = context.read<RepositoryBloc>().state;
      final tabs = state.tabs;
      if (tabs.length < 2) {
        return;
      }
      final activeIndex = tabs.indexWhere(
        (tab) => tab.repository.path == state.activePath,
      );
      final nextIndex = activeIndex < 0 ? 0 : (activeIndex + 1) % tabs.length;
      context.read<RepositoryBloc>().add(
        RepositoryTabSelected(tabs[nextIndex].repository.path),
      );
    }

    void quickOpen() {
      final tabs = context.read<RepositoryBloc>().state.tabs;
      unawaited(
        showCommandPalette(
          context,
          hint: l10n.quickOpenHint,
          items: [
            for (final tab in tabs)
              PaletteItem(
                label: tab.repository.name,
                hint: tab.repository.path,
                icon: Icons.account_tree_outlined,
                onSelected: () => context.read<RepositoryBloc>().add(
                  RepositoryTabSelected(tab.repository.path),
                ),
              ),
          ],
        ),
      );
    }

    void commandPalette() {
      unawaited(showWorkspaceCommandPalette(context));
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyW, control: true):
            closeActive,
        const SingleActivator(LogicalKeyboardKey.keyW, meta: true): closeActive,
        const SingleActivator(LogicalKeyboardKey.tab, control: true): cycleTab,
        const SingleActivator(LogicalKeyboardKey.tab, meta: true): cycleTab,
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            quickOpen,
        const SingleActivator(LogicalKeyboardKey.keyP, meta: true): quickOpen,
        const SingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        ): commandPalette,
        const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true):
            commandPalette,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
