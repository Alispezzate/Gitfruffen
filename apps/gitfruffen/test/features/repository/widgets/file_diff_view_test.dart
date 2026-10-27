import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/file_diff_view.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

const _fullOnlyLine = 'only in full file';

const _file = DiffFile(
  path: 'lib/main.dart',
  changeType: FileChangeType.modified,
  isBinary: false,
  insertions: 2,
  deletions: 2,
  hunks: [
    DiffHunk(
      header: '@@ -1,4 +1,6 @@',
      lines: [
        DiffLine(
          kind: DiffLineKind.context,
          content: 'context one',
          oldLine: 1,
          newLine: 1,
        ),
        DiffLine(kind: DiffLineKind.removed, content: 'old line', oldLine: 2),
        DiffLine(kind: DiffLineKind.added, content: 'new line', newLine: 2),
        DiffLine(kind: DiffLineKind.added, content: 'extra line', newLine: 3),
        DiffLine(
          kind: DiffLineKind.context,
          content: 'context two',
          oldLine: 3,
          newLine: 4,
        ),
        DiffLine(
          kind: DiffLineKind.context,
          content: 'context three',
          oldLine: 4,
          newLine: 5,
        ),
      ],
    ),
    DiffHunk(
      header: '@@ -10,4 +11,5 @@',
      lines: [
        DiffLine(
          kind: DiffLineKind.context,
          content: 'second context',
          oldLine: 10,
          newLine: 11,
        ),
        DiffLine(
          kind: DiffLineKind.removed,
          content: 'old second',
          oldLine: 11,
        ),
        DiffLine(kind: DiffLineKind.added, content: 'new second', newLine: 12),
        DiffLine(
          kind: DiffLineKind.context,
          content: 'second tail',
          oldLine: 12,
          newLine: 13,
        ),
      ],
    ),
  ],
);

const _compactFile = DiffFile(
  path: 'lib/feature.dart',
  changeType: FileChangeType.modified,
  isBinary: false,
  insertions: 1,
  deletions: 1,
  hunks: [
    DiffHunk(
      header: '@@ -1,2 +1,2 @@',
      lines: [
        DiffLine(
          kind: DiffLineKind.context,
          content: 'first context',
          oldLine: 1,
          newLine: 1,
        ),
        DiffLine(
          kind: DiffLineKind.removed,
          content: 'old feature',
          oldLine: 2,
        ),
        DiffLine(kind: DiffLineKind.added, content: 'new feature', newLine: 2),
      ],
    ),
    DiffHunk(
      header: '@@ -8,2 +8,2 @@',
      lines: [
        DiffLine(
          kind: DiffLineKind.context,
          content: 'second context',
          oldLine: 8,
          newLine: 8,
        ),
        DiffLine(kind: DiffLineKind.removed, content: 'old tail', oldLine: 9),
        DiffLine(kind: DiffLineKind.added, content: 'new tail', newLine: 9),
      ],
    ),
  ],
);

const _fullFile = DiffFile(
  path: 'lib/feature.dart',
  changeType: FileChangeType.modified,
  isBinary: false,
  insertions: 1,
  deletions: 1,
  hunks: [
    DiffHunk(
      header: '@@ -1,9 +1,9 @@',
      lines: [
        DiffLine(
          kind: DiffLineKind.context,
          content: 'first context',
          oldLine: 1,
          newLine: 1,
        ),
        DiffLine(
          kind: DiffLineKind.removed,
          content: 'old feature',
          oldLine: 2,
        ),
        DiffLine(kind: DiffLineKind.added, content: 'new feature', newLine: 2),
        DiffLine(
          kind: DiffLineKind.context,
          content: _fullOnlyLine,
          oldLine: 3,
          newLine: 3,
        ),
        DiffLine(
          kind: DiffLineKind.context,
          content: 'more context',
          oldLine: 4,
          newLine: 4,
        ),
        DiffLine(
          kind: DiffLineKind.context,
          content: 'second context',
          oldLine: 8,
          newLine: 8,
        ),
        DiffLine(kind: DiffLineKind.removed, content: 'old tail', oldLine: 9),
        DiffLine(kind: DiffLineKind.added, content: 'new tail', newLine: 9),
      ],
    ),
  ],
);

const _farCompactFile = DiffFile(
  path: 'lib/far.dart',
  changeType: FileChangeType.modified,
  isBinary: false,
  insertions: 1,
  deletions: 1,
  hunks: [
    DiffHunk(
      header: '@@ -1,2 +1,2 @@',
      lines: [
        DiffLine(
          kind: DiffLineKind.context,
          content: 'near context',
          oldLine: 1,
          newLine: 1,
        ),
        DiffLine(kind: DiffLineKind.removed, content: 'near old', oldLine: 2),
        DiffLine(kind: DiffLineKind.added, content: 'near change', newLine: 2),
      ],
    ),
    DiffHunk(
      header: '@@ -83,2 +83,2 @@',
      lines: [
        DiffLine(
          kind: DiffLineKind.context,
          content: 'tail context',
          oldLine: 83,
          newLine: 83,
        ),
        DiffLine(kind: DiffLineKind.removed, content: 'far old', oldLine: 84),
        DiffLine(kind: DiffLineKind.added, content: 'far change', newLine: 84),
      ],
    ),
  ],
);

final _farFullFile = DiffFile(
  path: 'lib/far.dart',
  changeType: FileChangeType.modified,
  isBinary: false,
  insertions: 1,
  deletions: 1,
  hunks: [
    DiffHunk(
      header: '@@ -1,84 +1,84 @@',
      lines: [
        const DiffLine(
          kind: DiffLineKind.context,
          content: 'near context',
          oldLine: 1,
          newLine: 1,
        ),
        const DiffLine(
          kind: DiffLineKind.removed,
          content: 'near old',
          oldLine: 2,
        ),
        const DiffLine(
          kind: DiffLineKind.added,
          content: 'near change',
          newLine: 2,
        ),
        for (var line = 3; line <= 82; line++)
          DiffLine(
            kind: DiffLineKind.context,
            content: 'context line $line',
            oldLine: line,
            newLine: line,
          ),
        const DiffLine(
          kind: DiffLineKind.context,
          content: 'tail context',
          oldLine: 83,
          newLine: 83,
        ),
        const DiffLine(
          kind: DiffLineKind.removed,
          content: 'far old',
          oldLine: 84,
        ),
        const DiffLine(
          kind: DiffLineKind.added,
          content: 'far change',
          newLine: 84,
        ),
      ],
    ),
  ],
);

final _signature = Signature(
  name: 'Ada Lovelace',
  email: 'ada@gitfruffen.dev',
  when: DateTime.utc(2026),
);
final _commit = Commit(
  oid: GitOid('c' * 40),
  message: 'develop: spike\n',
  summary: 'develop: spike',
  author: _signature,
  committer: _signature,
  parentOids: const [],
);

final _blame = [
  BlameLine(
    line: 1,
    commitOid: _commit.oid,
    summary: _commit.summary,
    author: _signature,
    isBoundary: true,
  ),
];

_MockGitRepository _repositoryWith({
  required DiffFile compactFile,
  required DiffFile fullFile,
  required List<Commit> history,
  required List<BlameLine> blame,
}) {
  final repository = _MockGitRepository();
  when(
    () => repository.diffWorkingTree(
      path: any(named: 'path'),
      staged: any(named: 'staged'),
      ignoreWhitespace: any(named: 'ignoreWhitespace'),
      contextLines: any(named: 'contextLines'),
    ),
  ).thenAnswer((invocation) async {
    final context = invocation.namedArguments[#contextLines] as int;
    final file = context > 3 ? fullFile : compactFile;
    return DiffResult(files: [file]);
  });
  when(
    () => repository.diffCommit(
      path: any(named: 'path'),
      oid: any(named: 'oid'),
      ignoreWhitespace: any(named: 'ignoreWhitespace'),
      contextLines: any(named: 'contextLines'),
    ),
  ).thenAnswer((_) async => DiffResult(files: [fullFile]));
  when(
    () => repository.blameFile(
      path: any(named: 'path'),
      filePath: any(named: 'filePath'),
      at: any(named: 'at'),
    ),
  ).thenAnswer((_) async => blame);
  when(
    () => repository.fileHistory(
      path: any(named: 'path'),
      filePath: any(named: 'filePath'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => history);
  return repository;
}

Widget _buildApp({
  required GitRepositoryContract repository,
  required DiffFile file,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<FileDiffBloc>(
        create: (context) => FileDiffBloc(
          repository: repository,
          request: OpenFileRequest(
            repositoryPath: '/tmp/gitfruffen-diff',
            file: file,
            source: FileDiffSource.staged,
          ),
        ),
        child: SizedBox(
          width: 800,
          height: 600,
          child: FileDiffView(onBack: () {}),
        ),
      ),
    ),
  );
}

Future<void> _pumpView(
  WidgetTester tester, {
  required GitRepositoryContract repository,
  required DiffFile file,
}) async {
  await tester.pumpWidget(_buildApp(repository: repository, file: file));
  await tester.pumpAndSettle();
}

Finder _iconButton(String tooltip) {
  return find.ancestor(
    of: find.byTooltip(tooltip),
    matching: find.byType(IconButton),
  );
}

IconButton _iconButtonWidget(WidgetTester tester, String tooltip) {
  return tester.widget<IconButton>(_iconButton(tooltip));
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const GitOid('0000000000000000000000000000000000000000'),
    );
  });

  late _MockGitRepository repository;

  setUp(() {
    repository = _repositoryWith(
      compactFile: _file,
      fullFile: _file,
      history: [_commit],
      blame: _blame,
    );
  });

  testWidgets('renders inline added and removed lines with markers', (
    tester,
  ) async {
    await _pumpView(tester, repository: repository, file: _file);

    expect(find.text('old line'), findsOneWidget);
    expect(find.text('new line'), findsOneWidget);
    expect(find.text('+'), findsWidgets);
    expect(find.text('-'), findsWidgets);
  });

  testWidgets('hunk view collapses context lines', (tester) async {
    await _pumpView(tester, repository: repository, file: _file);

    await tester.tap(find.byTooltip('Hunk view'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diff-hunk-view')), findsOneWidget);
    expect(find.text('context one'), findsNothing);
    expect(find.textContaining('unchanged lines'), findsWidgets);
  });

  testWidgets('inline view renders context lines and hunk headers', (
    tester,
  ) async {
    await _pumpView(tester, repository: repository, file: _file);

    await tester.tap(find.byTooltip('Inline view'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diff-inline-view')), findsOneWidget);
    expect(find.text('context one'), findsOneWidget);
    expect(find.text('@@ -1,4 +1,6 @@'), findsOneWidget);
    expect(find.text('@@ -10,4 +11,5 @@'), findsOneWidget);
  });

  testWidgets('split view shows both sides without overflow', (tester) async {
    await _pumpView(tester, repository: repository, file: _file);

    await tester.tap(find.byTooltip('Split view'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diff-split-view')), findsOneWidget);
    expect(find.text('old line'), findsOneWidget);
    expect(find.text('new line'), findsOneWidget);
    expect(find.text('extra line'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blame gutter shows deterministic authorship', (tester) async {
    await _pumpView(tester, repository: repository, file: _file);

    await tester.tap(find.text('Blame'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diff-blame-gutter')), findsWidgets);
    expect(find.textContaining('Ada Lovelace'), findsWidgets);
  });

  testWidgets('history dialog selects a commit and closes', (tester) async {
    await _pumpView(tester, repository: repository, file: _file);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('File history'), findsOneWidget);
    expect(find.text('develop: spike'), findsOneWidget);

    await tester.tap(find.text('develop: spike'));
    await tester.pumpAndSettle();

    expect(find.text('File history'), findsNothing);
    expect(find.byType(FileDiffView), findsOneWidget);
  });

  testWidgets('reloads blame after selecting a history commit', (tester) async {
    await _pumpView(tester, repository: repository, file: _file);
    await tester.tap(find.text('Blame'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ada Lovelace'), findsWidgets);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('develop: spike'));
    await tester.pumpAndSettle();

    expect(find.byType(FileDiffView), findsOneWidget);
    expect(find.textContaining('Ada Lovelace'), findsWidgets);
  });

  testWidgets('word wrap toggles per-line text wrapping', (tester) async {
    await _pumpView(tester, repository: repository, file: _file);

    final before = tester.widget<Text>(find.text('new line'));
    expect(before.softWrap, isNot(false));

    await tester.tap(find.byTooltip('Word wrap'));
    await tester.pump();

    final after = tester.widget<Text>(find.text('new line'));
    expect(after.softWrap, isFalse);
  });

  testWidgets('full file source hides compact-only context in hunk view', (
    tester,
  ) async {
    final fullRepository = _repositoryWith(
      compactFile: _compactFile,
      fullFile: _fullFile,
      history: [_commit],
      blame: _blame,
    );
    await _pumpView(tester, repository: fullRepository, file: _compactFile);

    expect(find.byKey(const Key('diff-inline-view')), findsOneWidget);
    expect(find.text(_fullOnlyLine), findsOneWidget);

    await tester.tap(find.byTooltip('Hunk view'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diff-hunk-view')), findsOneWidget);
    expect(find.text(_fullOnlyLine), findsNothing);

    await tester.tap(find.byTooltip('Inline view'));
    await tester.pumpAndSettle();
    expect(find.text(_fullOnlyLine), findsOneWidget);

    await tester.tap(find.byTooltip('Split view'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diff-split-view')), findsOneWidget);
    expect(find.text(_fullOnlyLine), findsWidgets);
  });

  testWidgets('change navigation moves between full-file change blocks', (
    tester,
  ) async {
    final fullRepository = _repositoryWith(
      compactFile: _compactFile,
      fullFile: _fullFile,
      history: [_commit],
      blame: _blame,
    );
    await _pumpView(tester, repository: fullRepository, file: _compactFile);

    expect(_iconButtonWidget(tester, 'Previous change').onPressed, isNull);
    expect(_iconButtonWidget(tester, 'Next change').onPressed, isNotNull);

    await tester.tap(_iconButton('Next change'));
    await tester.pumpAndSettle();

    expect(_iconButtonWidget(tester, 'Previous change').onPressed, isNotNull);
  });

  testWidgets('far change navigation scrolls it into the viewport', (
    tester,
  ) async {
    final farRepository = _repositoryWith(
      compactFile: _farCompactFile,
      fullFile: _farFullFile,
      history: [_commit],
      blame: _blame,
    );
    await _pumpView(tester, repository: farRepository, file: _farCompactFile);

    final farChange = find.text('far change');
    expect(farChange, findsOneWidget);
    expect(tester.getTopLeft(farChange).dy, greaterThan(600));

    await tester.tap(_iconButton('Next change'));
    await tester.pumpAndSettle();

    final dy = tester.getTopLeft(farChange).dy;
    expect(dy, greaterThanOrEqualTo(0));
    expect(dy, lessThan(600));
  });

  testWidgets('ignore whitespace toggles the diff without errors', (
    tester,
  ) async {
    await _pumpView(tester, repository: repository, file: _file);

    await tester.tap(find.byTooltip('Ignore whitespace'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Ignore whitespace'), findsOneWidget);
  });
}
