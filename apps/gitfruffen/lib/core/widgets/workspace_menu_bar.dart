import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/core/widgets/workspace_commands.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/presentation/dialogs/repository_dialogs.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Application menu bar for the workspace.
///
/// Uses the native menu bar on macOS and an in-window Material [MenuBar]
/// everywhere else.
class WorkspaceMenuBar extends StatelessWidget {
  const WorkspaceMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return PlatformMenuBar(
        menus: [
          PlatformMenu(
            label: l10n.menuFile,
            menus: [
              PlatformMenuItem(
                label: l10n.menuOpenRepository,
                onSelected: () => openRepositoryDialog(context),
              ),
              PlatformMenuItem(
                label: l10n.menuCloneRepository,
                onSelected: () => showCloneRepositoryDialog(context),
              ),
              PlatformMenuItem(
                label: l10n.menuNewRepository,
                onSelected: () => showNewRepositoryDialog(context),
              ),
              PlatformMenuItem(
                label: l10n.menuCloseRepository,
                onSelected: () => _closeActive(context),
              ),
            ],
          ),
          PlatformMenu(
            label: l10n.menuEdit,
            menus: [
              PlatformMenuItem(
                label: l10n.menuUndo,
                onSelected: () => confirmRepositoryUndo(context),
              ),
              PlatformMenuItem(
                label: l10n.menuRedo,
                onSelected: () => confirmRepositoryRedo(context),
              ),
            ],
          ),
          PlatformMenu(
            label: l10n.menuView,
            menus: [
              PlatformMenuItem(
                label: l10n.menuRepository,
                onSelected: () => context.go('/repository'),
              ),
              PlatformMenuItem(
                label: l10n.menuCommandPalette,
                onSelected: () => showWorkspaceCommandPalette(context),
              ),
              PlatformMenuItem(
                label: l10n.menuSettings,
                onSelected: () => context.go('/settings'),
              ),
            ],
          ),
          PlatformMenu(
            label: l10n.menuHelp,
            menus: [
              PlatformMenuItem(
                label: l10n.menuAbout,
                onSelected: () => _showAbout(context),
              ),
            ],
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final buttonStyle = _topLevelButtonStyle(theme);
    return Container(
      height: AppTheme.menuBarHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: MenuBar(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        ),
        children: [
          SubmenuButton(
            style: buttonStyle,
            menuChildren: [
              MenuItemButton(
                onPressed: () => openRepositoryDialog(context),
                child: Text(l10n.menuOpenRepository),
              ),
              MenuItemButton(
                onPressed: () => showCloneRepositoryDialog(context),
                child: Text(l10n.menuCloneRepository),
              ),
              MenuItemButton(
                onPressed: () => showNewRepositoryDialog(context),
                child: Text(l10n.menuNewRepository),
              ),
              MenuItemButton(
                onPressed: () => _closeActive(context),
                child: Text(l10n.menuCloseRepository),
              ),
            ],
            child: Text(l10n.menuFile),
          ),
          SubmenuButton(
            style: buttonStyle,
            menuChildren: [
              MenuItemButton(
                onPressed: () => confirmRepositoryUndo(context),
                child: Text(l10n.menuUndo),
              ),
              MenuItemButton(
                onPressed: () => confirmRepositoryRedo(context),
                child: Text(l10n.menuRedo),
              ),
            ],
            child: Text(l10n.menuEdit),
          ),
          SubmenuButton(
            style: buttonStyle,
            menuChildren: [
              MenuItemButton(
                onPressed: () => context.go('/repository'),
                child: Text(l10n.menuRepository),
              ),
              MenuItemButton(
                onPressed: () => showWorkspaceCommandPalette(context),
                child: Text(l10n.menuCommandPalette),
              ),
              MenuItemButton(
                onPressed: () => context.go('/settings'),
                child: Text(l10n.menuSettings),
              ),
            ],
            child: Text(l10n.menuView),
          ),
          SubmenuButton(
            style: buttonStyle,
            menuChildren: [
              MenuItemButton(
                onPressed: () => _showAbout(context),
                child: Text(l10n.menuAbout),
              ),
            ],
            child: Text(l10n.menuHelp),
          ),
        ],
      ),
    );
  }

  ButtonStyle _topLevelButtonStyle(ThemeData theme) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, AppTheme.menuBarHeight)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    textStyle: WidgetStatePropertyAll(
      theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
    ),
  );

  void _closeActive(BuildContext context) {
    final bloc = context.read<RepositoryBloc>();
    final path = bloc.state.activePath;
    bloc.add(
      path == null ? const RepositoryClosed() : RepositoryTabClosed(path),
    );
  }

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: l10n.appVersion,
    );
  }
}
