import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/services/file_picker_service.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Opens the native directory picker and opens the chosen repository.
Future<void> openRepositoryDialog(BuildContext context) async {
  final picker = context.read<FilePickerService>();
  final bloc = context.read<RepositoryBloc>();
  final l10n = AppLocalizations.of(context);

  final path = await picker.pickDirectory(
    title: l10n.openRepositoryDialogTitle,
  );
  if (path == null) {
    return;
  }
  bloc.add(RepositoryOpened(path));
}

/// Prompts for a remote URL and a local path, then clones the repository.
Future<void> showCloneRepositoryDialog(BuildContext context) async {
  final bloc = context.read<RepositoryBloc>();
  final l10n = AppLocalizations.of(context);
  final urlController = TextEditingController();
  final pathController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.cloneDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: InputDecoration(labelText: l10n.remoteUrlLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pathController,
            decoration: InputDecoration(labelText: l10n.localPathLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.cloneConfirmButton),
        ),
      ],
    ),
  );

  if (confirmed ?? false) {
    final url = urlController.text.trim();
    final localPath = pathController.text.trim();
    if (url.isNotEmpty && localPath.isNotEmpty) {
      bloc.add(RepositoryCloned(url: url, localPath: localPath));
    }
  }
  urlController.dispose();
  pathController.dispose();
}

/// Confirms the undo action and moves HEAD back when the user agrees.
Future<void> confirmRepositoryUndo(BuildContext context) => _confirm(
  context,
  title: AppLocalizations.of(context).undoDialogTitle,
  message: AppLocalizations.of(context).undoDialogMessage,
  onConfirm: () => context.read<RepositoryBloc>().add(const UndoRequested()),
);

/// Confirms the redo action and re-applies the last undone HEAD move.
Future<void> confirmRepositoryRedo(BuildContext context) => _confirm(
  context,
  title: AppLocalizations.of(context).redoDialogTitle,
  message: AppLocalizations.of(context).redoDialogMessage,
  onConfirm: () => context.read<RepositoryBloc>().add(const RedoRequested()),
);

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.confirmButton),
        ),
      ],
    ),
  );
  if ((confirmed ?? false) && context.mounted) {
    onConfirm();
  }
}

/// Prompts for a folder and initialises a new repository there.
Future<void> showNewRepositoryDialog(BuildContext context) async {
  final bloc = context.read<RepositoryBloc>();
  final l10n = AppLocalizations.of(context);
  final pathController = TextEditingController();

  final path = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.newRepositoryDialogTitle),
      content: TextField(
        controller: pathController,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.localPathLabel),
        onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(pathController.text),
          child: Text(l10n.newRepositoryConfirmButton),
        ),
      ],
    ),
  );

  final trimmed = path?.trim() ?? '';
  if (trimmed.isNotEmpty) {
    bloc.add(RepositoryInitialized(trimmed));
  }
  pathController.dispose();
}
