import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_painter.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_view.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

void main() {
  Signature signature() => Signature(
    name: 'Ada Lovelace',
    email: 'ada@gitfruffen.dev',
    when: DateTime.utc(2026),
  );

  final first = Commit(
    oid: GitOid('1' * 40),
    message: 'first commit\n',
    summary: 'first commit',
    author: signature(),
    committer: signature(),
    parentOids: const [],
  );
  final second = Commit(
    oid: GitOid('2' * 40),
    message: 'second commit\n',
    summary: 'second commit',
    author: signature(),
    committer: signature(),
    parentOids: const [],
  );

  const repository = GitRepository(
    path: '/tmp/gitfruffen-a',
    name: 'gitfruffen-a',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const status = RepositoryStatus(
    changes: [],
    currentBranchName: 'main',
    headCommit: null,
  );

  testWidgets('selects a commit when its row is tapped', (tester) async {
    GitOid? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 400,
            child: CommitGraphView(
              tab: RepositoryTab(
                repository: repository,
                status: status,
                graph: [first, second],
              ),
              onCommitSelected: (commit) => selected = commit.oid,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('second commit'));
    await tester.pump();

    expect(selected, second.oid);
  });

  testWidgets('renders the branch/tag, graph and message headers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 400,
            child: CommitGraphView(
              tab: RepositoryTab(
                repository: repository,
                status: status,
                graph: [first],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BRANCH / TAG'), findsOneWidget);
    expect(find.text('GRAPH'), findsOneWidget);
    expect(find.text('COMMIT MESSAGE'), findsOneWidget);
  });

  testWidgets('renders a WIP row and selects it on tap', (tester) async {
    var wipSelected = false;
    final changes = [
      const FileChange(
        path: 'lib/main.dart',
        type: FileChangeType.modified,
        staged: false,
        unstaged: true,
        conflicted: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 400,
            child: CommitGraphView(
              tab: RepositoryTab(
                repository: repository,
                status: RepositoryStatus(
                  changes: changes,
                  currentBranchName: 'main',
                  headCommit: null,
                ),
              ),
              onWipSelected: () => wipSelected = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('// WIP'), findsOneWidget);
    expect(find.text('WIP'), findsOneWidget);

    await tester.tap(find.text('WIP'));
    await tester.pump();

    expect(wipSelected, isTrue);
  });

  Widget host(CommitGraphView view, {double width = 900}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(width: width, height: 400, child: view),
    ),
  );

  testWidgets('sizes the graph painter to the row height', (tester) async {
    await tester.pumpWidget(
      host(
        CommitGraphView(
          tab: RepositoryTab(
            repository: repository,
            status: status,
            graph: [first],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final painter = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is CommitGraphPainter,
    );
    expect(painter, findsOneWidget);
    expect(tester.getSize(painter).height, greaterThan(0));
  });

  testWidgets('renders many lanes at 1000px without exceptions', (
    tester,
  ) async {
    final commits = [
      for (var i = 0; i < 24; i++)
        Commit(
          oid: GitOid((i + 1).toRadixString(16).padLeft(40, '0')),
          message: 'commit $i\n',
          summary: 'commit $i',
          author: signature(),
          committer: signature(),
          parentOids: [
            if (i + 1 < 24) GitOid((i + 2).toRadixString(16).padLeft(40, '0')),
            GitOid((1000 + i).toRadixString(16).padLeft(40, '0')),
          ],
        ),
    ];

    await tester.pumpWidget(
      host(
        CommitGraphView(
          tab: RepositoryTab(
            repository: repository,
            status: status,
            graph: commits,
          ),
        ),
        width: 1000,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
