import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_event.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// How the diff body lays out the lines of the open file.
enum DiffViewMode { hunk, inline, split }

/// A contiguous run of added/removed lines inside one hunk.
class _ChangeBlock {
  const _ChangeBlock({
    required this.hunkIndex,
    required this.lineIndex,
    required this.key,
  });

  final int hunkIndex;
  final int lineIndex;
  final GlobalKey key;
}

/// Diff of the file owned by `FileDiffBloc`, with an advanced toolbar, blame
/// gutter and three render modes.
class FileDiffView extends StatefulWidget {
  const FileDiffView({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<FileDiffView> createState() => _FileDiffViewState();
}

class _FileDiffViewState extends State<FileDiffView> {
  static const double _blameWidth = 190;
  static const double _numberWidth = 40;
  static const double _markerWidth = 16;

  DiffViewMode _mode = DiffViewMode.inline;
  bool _wordWrap = true;
  bool _showBlame = false;
  int _currentChange = 0;
  List<_ChangeBlock> _changes = const [];
  Map<(int, int), GlobalKey> _changeKeys = const {};
  String? _filePath;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<FileDiffBloc>();
    _rebuildChanges(bloc.state.file);
    if (!bloc.state.fullFile) {
      bloc.add(const FileDiffFullFileToggled(true));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _rebuildChanges(DiffFile file) {
    final pathChanged = _filePath != file.path;
    _filePath = file.path;
    final changes = <_ChangeBlock>[];
    final keys = <(int, int), GlobalKey>{};
    for (var hunkIndex = 0; hunkIndex < file.hunks.length; hunkIndex++) {
      final lines = file.hunks[hunkIndex].lines;
      var insideBlock = false;
      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final isChange = lines[lineIndex].kind != DiffLineKind.context;
        if (isChange && !insideBlock) {
          final key = GlobalKey();
          changes.add(
            _ChangeBlock(hunkIndex: hunkIndex, lineIndex: lineIndex, key: key),
          );
          keys[(hunkIndex, lineIndex)] = key;
        }
        insideBlock = isChange;
      }
    }
    _changes = changes;
    _changeKeys = keys;
    if (pathChanged || changes.isEmpty) {
      _currentChange = 0;
    } else if (_currentChange >= changes.length) {
      _currentChange = changes.length - 1;
    }
  }

  void _resetForFile(DiffFile file) {
    final pathChanged = _filePath != file.path;
    setState(() => _rebuildChanges(file));
    if (!pathChanged) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  void _goToChange(int index) {
    if (index < 0 || index >= _changes.length) {
      return;
    }
    setState(() => _currentChange = index);
    final target = _changes[index].key.currentContext;
    if (target == null) {
      return;
    }
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 180),
        alignment: 0.05,
      ),
    );
  }

  void _setMode(DiffViewMode mode, FileDiffState state, FileDiffBloc bloc) {
    setState(() => _mode = mode);
    final wantsFullFile = mode != DiffViewMode.hunk;
    if (state.fullFile != wantsFullFile) {
      bloc.add(FileDiffFullFileToggled(wantsFullFile));
    }
  }

  int? _currentHunkIndex() {
    if (_currentChange >= _changes.length) {
      return null;
    }
    return _changes[_currentChange].hunkIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<FileDiffBloc>();
    final state = context.watch<FileDiffBloc>().state;
    return BlocListener<FileDiffBloc, FileDiffState>(
      listenWhen: (previous, next) => previous.file != next.file,
      listener: (context, state) => _resetForFile(state.file),
      child: Column(
        children: [
          _toolbar(theme, l10n, state, bloc),
          if (state.isLoadingDiff) const LinearProgressIndicator(minHeight: 2),
          if (_showBlame && state.blame.isEmpty && state.isLoadingBlame)
            _status(theme, l10n.diffBlameLoading),
          if (_showBlame &&
              state.blame.isEmpty &&
              !state.isLoadingBlame &&
              state.failure != null)
            _status(theme, l10n.diffBlameUnavailable),
          const Divider(height: 1),
          Expanded(child: _body(theme, l10n, state)),
        ],
      ),
    );
  }

  Widget _toolbar(
    ThemeData theme,
    AppLocalizations l10n,
    FileDiffState state,
    FileDiffBloc bloc,
  ) {
    final file = state.file;
    final canGoPrevious = _currentChange > 0;
    final canGoNext = _currentChange < _changes.length - 1;
    return SizedBox(
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            _iconButton(
              theme: theme,
              icon: Icons.arrow_back,
              tooltip: l10n.closeFileView,
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Text(
                file.path,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '+${file.insertions}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: AppColors.added,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '-${file.deletions}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: AppColors.deleted,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.65,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _textButton(
                      theme: theme,
                      label: l10n.diffBlame,
                      selected: _showBlame,
                      onPressed: () {
                        final show = !_showBlame;
                        setState(() => _showBlame = show);
                        if (show && state.blame.isEmpty) {
                          bloc.add(const FileDiffBlameRequested());
                        }
                      },
                    ),
                    _textButton(
                      theme: theme,
                      label: l10n.diffHistory,
                      onPressed: () => _openHistory(bloc, l10n),
                    ),
                    _iconButton(
                      theme: theme,
                      icon: Icons.keyboard_arrow_up,
                      tooltip: l10n.diffPreviousChange,
                      onPressed: canGoPrevious
                          ? () => _goToChange(_currentChange - 1)
                          : null,
                    ),
                    _iconButton(
                      theme: theme,
                      icon: Icons.keyboard_arrow_down,
                      tooltip: l10n.diffNextChange,
                      onPressed: canGoNext
                          ? () => _goToChange(_currentChange + 1)
                          : null,
                    ),
                    _iconButton(
                      theme: theme,
                      icon: Icons.view_list_outlined,
                      tooltip: l10n.diffHunkView,
                      selected: _mode == DiffViewMode.hunk,
                      onPressed: () => _setMode(DiffViewMode.hunk, state, bloc),
                    ),
                    _iconButton(
                      theme: theme,
                      icon: Icons.view_stream_outlined,
                      tooltip: l10n.diffInlineView,
                      selected: _mode == DiffViewMode.inline,
                      onPressed: () =>
                          _setMode(DiffViewMode.inline, state, bloc),
                    ),
                    _iconButton(
                      theme: theme,
                      icon: Icons.view_column_outlined,
                      tooltip: l10n.diffSplitView,
                      selected: _mode == DiffViewMode.split,
                      onPressed: () =>
                          _setMode(DiffViewMode.split, state, bloc),
                    ),
                    _iconButton(
                      theme: theme,
                      icon: Icons.space_bar,
                      tooltip: l10n.diffIgnoreWhitespace,
                      selected: state.ignoreWhitespace,
                      onPressed: file.isBinary
                          ? null
                          : () => bloc.add(
                              FileDiffWhitespaceToggled(
                                !state.ignoreWhitespace,
                              ),
                            ),
                    ),
                    _iconButton(
                      theme: theme,
                      icon: Icons.wrap_text,
                      tooltip: l10n.diffWordWrap,
                      selected: _wordWrap,
                      onPressed: () => setState(() => _wordWrap = !_wordWrap),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required ThemeData theme,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool selected = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 16,
      style: IconButton.styleFrom(
        foregroundColor: selected ? theme.colorScheme.primary : null,
        backgroundColor: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : null,
        minimumSize: const Size(30, 30),
        maximumSize: const Size(30, 30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon),
    );
  }

  Widget _textButton({
    required ThemeData theme,
    required String label,
    required VoidCallback? onPressed,
    bool selected = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected ? theme.colorScheme.primary : null,
        backgroundColor: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : null,
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _status(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _body(ThemeData theme, AppLocalizations l10n, FileDiffState state) {
    final file = state.file;
    if (file.isBinary) {
      return Center(child: Text(l10n.diffBinaryFile));
    }
    if (file.hunks.isEmpty) {
      return Center(child: Text(l10n.diffNoChanges));
    }
    return switch (_mode) {
      DiffViewMode.hunk => _hunkBody(theme, state),
      DiffViewMode.inline => _inlineBody(theme, state),
      DiffViewMode.split => _splitBody(theme, state),
    };
  }

  TextStyle _mono(ThemeData theme) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: theme.textTheme.bodyMedium?.color,
    );
  }

  TextStyle _numberStyle(TextStyle mono, ThemeData theme) {
    return mono.copyWith(fontSize: 11, color: theme.textTheme.bodySmall?.color);
  }

  Map<int, BlameLine> _blameByLine(FileDiffState state) {
    return {for (final line in state.blame) line.line: line};
  }

  String? Function(DiffLine) _blameLookup(Map<int, BlameLine> blameByLine) {
    GitOid? previous;
    return (line) {
      if (!_showBlame || line.newLine == null) {
        return null;
      }
      final blame = blameByLine[line.newLine!];
      if (blame == null) {
        return null;
      }
      final label = blame.commitOid == previous ? null : _blameLabel(blame);
      previous = blame.commitOid;
      return label;
    };
  }

  String _blameLabel(BlameLine blame) {
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(blame.author.when.toLocal());
    return '${blame.author.name} ${blame.commitOid.short} $date';
  }

  Widget _bodyListView(Key key, List<Widget> children) {
    // ponytail: full-file mode already loads the whole file, so building every
    // row is acceptable; a lazy list would need offset-based navigation.
    return SingleChildScrollView(
      key: key,
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _hunkBody(ThemeData theme, FileDiffState state) {
    final file = state.file;
    final mono = _mono(theme);
    final number = _numberStyle(mono, theme);
    final blameFor = _blameLookup(_blameByLine(state));
    return _bodyListView(const Key('diff-hunk-view'), [
      for (var index = 0; index < file.hunks.length; index++)
        _hunkCard(index, file.hunks[index], mono, number, blameFor),
    ]);
  }

  Widget _hunkCard(
    int index,
    DiffHunk hunk,
    TextStyle mono,
    TextStyle number,
    String? Function(DiffLine) blameFor,
  ) {
    final theme = Theme.of(context);
    final current = _currentHunkIndex() == index;
    final rows = <Widget>[];
    var contextRun = 0;

    void flushContext() {
      if (contextRun == 0) {
        return;
      }
      rows.add(_collapsedRow(contextRun, mono));
      contextRun = 0;
    }

    for (var lineIndex = 0; lineIndex < hunk.lines.length; lineIndex++) {
      final line = hunk.lines[lineIndex];
      if (line.kind == DiffLineKind.context) {
        contextRun++;
        continue;
      }
      flushContext();
      rows.add(
        _unifiedRow(
          line,
          mono,
          number,
          blameFor(line),
          key: _changeKeys[(index, lineIndex)],
        ),
      );
    }
    flushContext();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(
          color: current
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: ValueKey('diff-hunk-$index'),
            color: current
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              hunk.header,
              style: mono.copyWith(
                fontWeight: FontWeight.w600,
                color: current ? theme.colorScheme.primary : null,
              ),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _collapsedRow(int count, TextStyle mono) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        l10n.diffUnchangedLines(count),
        style: mono.copyWith(
          fontSize: 11,
          color: theme.textTheme.bodySmall?.color,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _inlineBody(ThemeData theme, FileDiffState state) {
    final file = state.file;
    final mono = _mono(theme);
    final number = _numberStyle(mono, theme);
    final blameFor = _blameLookup(_blameByLine(state));
    return _bodyListView(const Key('diff-inline-view'), [
      for (final (index, hunk) in file.hunks.indexed) ...[
        _hunkHeader(index, hunk.header, mono),
        for (final (lineIndex, line) in hunk.lines.indexed)
          _unifiedRow(
            line,
            mono,
            number,
            blameFor(line),
            key: _changeKeys[(index, lineIndex)],
          ),
      ],
    ]);
  }

  Widget _hunkHeader(int index, String header, TextStyle mono) {
    final theme = Theme.of(context);
    final current = _currentHunkIndex() == index;
    return Container(
      color: current
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        header,
        key: ValueKey('diff-hunk-$index'),
        style: mono.copyWith(
          fontWeight: FontWeight.w600,
          color: current ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }

  Widget _unifiedRow(
    DiffLine line,
    TextStyle mono,
    TextStyle number,
    String? blameLabel, {
    Key? key,
  }) {
    return Container(
      key: key,
      color: _lineTint(line.kind),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showBlame) _blameCell(blameLabel),
          _lineNumber(line.oldLine, number),
          _lineNumber(line.newLine, number),
          _marker(line.kind, mono),
          Expanded(child: _code(line.content, mono)),
        ],
      ),
    );
  }

  Widget _splitBody(ThemeData theme, FileDiffState state) {
    final file = state.file;
    final mono = _mono(theme);
    final number = _numberStyle(mono, theme);
    final blameFor = _blameLookup(_blameByLine(state));
    return _bodyListView(const Key('diff-split-view'), [
      for (final (index, hunk) in file.hunks.indexed) ...[
        _hunkHeader(index, hunk.header, mono),
        ..._splitRows(index, hunk, mono, number, blameFor),
      ],
    ]);
  }

  List<Widget> _splitRows(
    int hunkIndex,
    DiffHunk hunk,
    TextStyle mono,
    TextStyle number,
    String? Function(DiffLine) blameFor,
  ) {
    final rows = <Widget>[];
    var index = 0;
    while (index < hunk.lines.length) {
      final line = hunk.lines[index];
      if (line.kind == DiffLineKind.context) {
        rows.add(
          _splitRow(
            oldLine: line,
            newLine: line,
            mono: mono,
            number: number,
            newBlame: blameFor(line),
          ),
        );
        index++;
        continue;
      }
      final blockStart = index;
      final removed = <DiffLine>[];
      final added = <DiffLine>[];
      while (index < hunk.lines.length &&
          hunk.lines[index].kind != DiffLineKind.context) {
        final changed = hunk.lines[index];
        if (changed.kind == DiffLineKind.removed) {
          removed.add(changed);
        } else {
          added.add(changed);
        }
        index++;
      }
      final pairs = removed.length > added.length
          ? removed.length
          : added.length;
      for (var pair = 0; pair < pairs; pair++) {
        final oldLine = pair < removed.length ? removed[pair] : null;
        final newLine = pair < added.length ? added[pair] : null;
        rows.add(
          _splitRow(
            oldLine: oldLine,
            newLine: newLine,
            mono: mono,
            number: number,
            newBlame: newLine == null ? null : blameFor(newLine),
            key: pair == 0 ? _changeKeys[(hunkIndex, blockStart)] : null,
          ),
        );
      }
    }
    return rows;
  }

  Widget _splitRow({
    required DiffLine? oldLine,
    required DiffLine? newLine,
    required TextStyle mono,
    required TextStyle number,
    required String? newBlame,
    Key? key,
  }) {
    // ponytail: IntrinsicHeight keeps both halves of a paired row equal in
    // height; cheap enough for a diff pane.
    return IntrinsicHeight(
      key: key,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _splitHalf(
              line: oldLine,
              lineNumber: oldLine?.oldLine,
              mono: mono,
              numberStyle: number,
              blameLabel: null,
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _splitHalf(
              line: newLine,
              lineNumber: newLine?.newLine,
              mono: mono,
              numberStyle: number,
              blameLabel: newBlame,
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitHalf({
    required DiffLine? line,
    required int? lineNumber,
    required TextStyle mono,
    required TextStyle numberStyle,
    required String? blameLabel,
  }) {
    return Container(
      color: _lineTint(line?.kind),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showBlame) _blameCell(blameLabel),
          _lineNumber(lineNumber, numberStyle),
          _marker(line?.kind, mono),
          Expanded(
            child: line == null
                ? const SizedBox.shrink()
                : _code(line.content, mono),
          ),
        ],
      ),
    );
  }

  Color? _lineTint(DiffLineKind? kind) {
    return switch (kind) {
      DiffLineKind.added => AppColors.added.withValues(alpha: 0.12),
      DiffLineKind.removed => AppColors.deleted.withValues(alpha: 0.12),
      DiffLineKind.context || null => null,
    };
  }

  Widget _lineNumber(int? value, TextStyle style) {
    return SizedBox(
      width: _numberWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          value?.toString() ?? '-',
          textAlign: TextAlign.right,
          style: style,
        ),
      ),
    );
  }

  Widget _marker(DiffLineKind? kind, TextStyle style) {
    return SizedBox(
      width: _markerWidth,
      child: Text(
        switch (kind) {
          DiffLineKind.added => '+',
          DiffLineKind.removed => '-',
          DiffLineKind.context || null => ' ',
        },
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }

  Widget _code(String content, TextStyle style) {
    final text = content.isEmpty ? ' ' : content;
    if (_wordWrap) {
      return Text(text, style: style);
    }
    // ponytail: scrolling each long line on its own is the lazy approach; a
    // shared two-axis viewport would need custom scroll plumbing.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(text, softWrap: false, style: style),
    );
  }

  Widget _blameCell(String? label) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('diff-blame-gutter'),
      width: _blameWidth,
      padding: const EdgeInsets.only(right: 6),
      child: label == null
          ? const SizedBox.shrink()
          : Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
    );
  }

  void _openHistory(FileDiffBloc bloc, AppLocalizations l10n) {
    bloc.add(const FileDiffHistoryRequested());
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => BlocProvider<FileDiffBloc>.value(
          value: bloc,
          child: AlertDialog(
            title: Text(l10n.diffHistoryTitle),
            content: SizedBox(
              width: 520,
              height: 420,
              child: BlocBuilder<FileDiffBloc, FileDiffState>(
                builder: (context, state) =>
                    _historyContent(dialogContext, state, l10n),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancelButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyContent(
    BuildContext dialogContext,
    FileDiffState state,
    AppLocalizations l10n,
  ) {
    if (state.isLoadingHistory && state.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.diffHistoryLoading),
          ],
        ),
      );
    }
    if (state.history.isEmpty) {
      return Center(child: Text(l10n.diffHistoryEmpty));
    }
    return ListView.separated(
      itemCount: state.history.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final commit = state.history[index];
        final date = MaterialLocalizations.of(
          context,
        ).formatShortDate(commit.author.when.toLocal());
        return ListTile(
          title: Text(commit.summary, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${commit.oid.short} · ${commit.author.name} · $date',
            overflow: TextOverflow.ellipsis,
          ),
          trailing: state.commitOid == commit.oid
              ? const Icon(Icons.check, size: 16)
              : null,
          onTap: () {
            final bloc = context.read<FileDiffBloc>()
              ..add(FileDiffHistoryCommitSelected(commit.oid));
            if (_showBlame) {
              bloc.add(const FileDiffBlameRequested());
            }
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}
