import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Commit message composer pinned below the working tree changes.
class CommitComposer extends StatefulWidget {
  const CommitComposer({required this.tab, super.key});

  final RepositoryTab tab;

  @override
  State<CommitComposer> createState() => _CommitComposerState();
}

class _CommitComposerState extends State<CommitComposer> {
  final TextEditingController _summary = TextEditingController();
  final TextEditingController _description = TextEditingController();
  bool _amend = false;

  @override
  void dispose() {
    _summary.dispose();
    _description.dispose();
    super.dispose();
  }

  void _toggleAmend(bool? value) {
    final amend = value ?? false;
    setState(() => _amend = amend);
    final head = widget.tab.status.headCommit;
    if (!amend || head == null) {
      return;
    }
    final lines = head.message.split('\n');
    _summary.text = lines.first.trim();
    _description.text = lines.skip(1).join('\n').trim();
  }

  void _submit() {
    final summary = _summary.text.trim();
    if (summary.isEmpty) {
      return;
    }
    final description = _description.text.trim();
    final message = description.isEmpty ? summary : '$summary\n\n$description';
    context.read<RepositoryBloc>().add(CommitSubmitted(message, amend: _amend));
    _summary.clear();
    _description.clear();
    setState(() => _amend = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isBusy = context.read<RepositoryBloc>().state.isBusy;
    final canCommit =
        !isBusy &&
        (_amend || widget.tab.status.stagedCount > 0) &&
        _summary.text.trim().isNotEmpty;

    OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      borderSide: BorderSide.none,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _summary,
            maxLength: 72,
            enabled: !isBusy,
            onChanged: (_) => setState(() {}),
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: l10n.commitSummaryLabel,
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              counterStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: border(),
              enabledBorder: border(),
              focusedBorder: border(),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 3,
            enabled: !isBusy,
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: l10n.commitDescriptionLabel,
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: border(),
              enabledBorder: border(),
              focusedBorder: border(),
            ),
          ),
          const SizedBox(height: 2),
          InkWell(
            onTap: isBusy ? null : () => _toggleAmend(!_amend),
            child: Row(
              children: [
                Checkbox(
                  value: _amend,
                  onChanged: isBusy ? null : _toggleAmend,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    l10n.amendPreviousCommit,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: FilledButton(
              onPressed: canCommit ? _submit : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(l10n.commitButton),
            ),
          ),
        ],
      ),
    );
  }
}
