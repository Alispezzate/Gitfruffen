import 'package:flutter/material.dart';
import 'package:gitfruffen/core/theme/app_theme.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// A selectable entry shown in the command palette.
class PaletteItem {
  const PaletteItem({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.hint,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final String? hint;
}

/// Whether [query] is an ordered, case-insensitive subsequence of [text].
bool paletteMatches(String query, String text) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return true;
  }

  final haystack = text.toLowerCase();
  var from = 0;
  for (final character in needle.split('')) {
    final index = haystack.indexOf(character, from);
    if (index == -1) {
      return false;
    }
    from = index + 1;
  }
  return true;
}

/// Shows the shared command palette and runs the selected item, if any.
Future<void> showCommandPalette(
  BuildContext context, {
  required String hint,
  required List<PaletteItem> items,
}) async {
  final selected = await showDialog<PaletteItem>(
    context: context,
    builder: (_) => _PaletteDialog(hint: hint, items: items),
  );
  if (selected != null && context.mounted) {
    selected.onSelected();
  }
}

class _PaletteDialog extends StatefulWidget {
  const _PaletteDialog({required this.hint, required this.items});

  final String hint;
  final List<PaletteItem> items;

  @override
  State<_PaletteDialog> createState() => _PaletteDialogState();
}

class _PaletteDialogState extends State<_PaletteDialog> {
  late final TextEditingController _controller;
  late List<PaletteItem> _filtered;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      _filtered = widget.items
          .where(
            (item) => paletteMatches(query, '${item.label} ${item.hint ?? ''}'),
          )
          .toList();
    });
  }

  void _selectFirst() {
    if (_filtered.isEmpty) {
      return;
    }
    Navigator.of(context).pop(_filtered.first);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _filter,
              onSubmitted: (_) => _selectFirst(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: widget.hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        l10n.paletteNoResults,
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final item = _filtered[index];
                        return ListTile(
                          leading: Icon(item.icon, size: 16),
                          title: Text(item.label),
                          subtitle: item.hint == null
                              ? null
                              : Text(
                                  item.hint!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
