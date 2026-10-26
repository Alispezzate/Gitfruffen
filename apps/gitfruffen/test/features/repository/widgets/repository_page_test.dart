import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/repository_page.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepositoryBloc extends Mock implements RepositoryBloc {}

void main() {
  const repository = GitRepository(
    path: '/tmp/gitfruffen-a',
    name: 'gitfruffen-a',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );

  Signature signature() => Signature(
    name: 'Ada Lovelace',
    email: 'ada@gitfruffen.dev',
    when: DateTime.utc(2026),
  );

  Commit commit(String id, String summary) => Commit(
    oid: GitOid(id * 40),
    message: '$summary\n',
    summary: summary,
    author: signature(),
    committer: signature(),
    parentOids: const [],
  );

  final graph = [
    commit('1', 'first commit'),
    commit('2', 'second commit'),
    commit('3', 'third commit'),
  ];
  const status = RepositoryStatus(
    changes: [
      FileChange(
        path: 'lib/main.dart',
        type: FileChangeType.modified,
        staged: true,
        unstaged: false,
        conflicted: false,
      ),
    ],
    currentBranchName: 'main',
    headCommit: null,
  );
  final tab = RepositoryTab(
    repository: repository,
    status: status,
    graph: graph,
    stagedDiff: const DiffResult(
      files: [
        DiffFile(
          path: 'lib/main.dart',
          changeType: FileChangeType.modified,
          isBinary: false,
          insertions: 1,
          deletions: 1,
        ),
      ],
    ),
  );

  testWidgets('lays out at 900x600 with the terminal open', (tester) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = _MockRepositoryBloc();
    when(
      () => bloc.state,
    ).thenReturn(RepositoryReady(tabs: [tab], activePath: repository.path));
    when(
      () => bloc.stream,
    ).thenAnswer((_) => const Stream<RepositoryState>.empty());
    when(() => bloc.canUndo).thenReturn(false);
    when(() => bloc.canRedo).thenReturn(false);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<RepositoryBloc>.value(
          value: bloc,
          child: const Scaffold(body: RepositoryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Toggle terminal'));
    await tester.pumpAndSettle();

    expect(
      find.text('Terminal is not available in this build.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
