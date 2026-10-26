import 'package:flutter/material.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Collapsible terminal panel shown below the graph and right panel.
class TerminalPanel extends StatelessWidget {
  const TerminalPanel({
    required this.expanded,
    required this.onToggle,
    required this.onClose,
    this.bodyHeight,
    super.key,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  /// Height of the terminal body when expanded, capped by the caller to fit
  /// short windows. Defaults to [AppTheme.terminalBodyHeight].
  final double? bodyHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final headerColor = theme.brightness == Brightness.dark
        ? AppColors.surfaceElevated
        : AppColors.surfaceElevatedLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppTheme.terminalHeaderHeight,
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                '>_ ${l10n.terminalTitle}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: expanded
                    ? l10n.collapseTerminalTooltip
                    : l10n.terminalToggleTooltip,
                onPressed: onToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                icon: Icon(expanded ? Icons.expand_more : Icons.expand_less),
              ),
              IconButton(
                tooltip: l10n.closeTerminalTooltip,
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                visualDensity: VisualDensity.compact,
                iconSize: 15,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        if (expanded)
          Container(
            height: bodyHeight ?? AppTheme.terminalBodyHeight,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.scaffoldBackgroundColor,
            child: Text(
              l10n.terminalUnavailable,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
      ],
    );
  }
}
