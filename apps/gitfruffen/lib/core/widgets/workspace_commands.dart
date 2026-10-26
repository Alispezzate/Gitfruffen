import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/widgets/command_palette.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/presentation/dialogs/repository_dialogs.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Shows the workspace command palette, wired to the repository actions.
Future<void> showWorkspaceCommandPalette(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final activePath = context.read<RepositoryBloc>().state.activePath;

  await showCommandPalette(
    context,
    hint: l10n.commandPaletteHint,
    items: [
      PaletteItem(
        label: l10n.openRepositoryTitle,
        icon: Icons.folder_open_outlined,
        onSelected: () => openRepositoryDialog(context),
      ),
      PaletteItem(
        label: l10n.cloneDialogTitle,
        icon: Icons.cloud_download_outlined,
        onSelected: () => showCloneRepositoryDialog(context),
      ),
      PaletteItem(
        label: l10n.newRepositoryDialogTitle,
        icon: Icons.create_new_folder_outlined,
        onSelected: () => showNewRepositoryDialog(context),
      ),
      PaletteItem(
        label: l10n.refreshTooltip,
        icon: Icons.refresh,
        onSelected: () =>
            context.read<RepositoryBloc>().add(const RepositoryRefreshed()),
      ),
      PaletteItem(
        label: l10n.fetchTooltip,
        icon: Icons.cloud_download_outlined,
        onSelected: () =>
            context.read<RepositoryBloc>().add(const RepositoryFetched()),
      ),
      PaletteItem(
        label: l10n.pullTooltip,
        icon: Icons.south,
        onSelected: () =>
            context.read<RepositoryBloc>().add(const RepositoryPulled()),
      ),
      PaletteItem(
        label: l10n.pushTooltip,
        icon: Icons.north,
        onSelected: () =>
            context.read<RepositoryBloc>().add(const RepositoryPushed()),
      ),
      PaletteItem(
        label: l10n.navSettings,
        icon: Icons.settings_outlined,
        onSelected: () => context.go('/settings'),
      ),
      if (activePath != null)
        PaletteItem(
          label: l10n.closeRepositoryTooltip,
          icon: Icons.close,
          onSelected: () => context.read<RepositoryBloc>().add(
            RepositoryTabClosed(activePath),
          ),
        ),
    ],
  );
}
