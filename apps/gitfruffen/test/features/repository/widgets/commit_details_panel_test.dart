import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/commit_details_panel.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepositoryBloc extends Mock implements RepositoryBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RepositoryRefreshed());
  });

  const repository = GitRepository(
    path: '/tmp/gitfruffen-a',
    name: 'gitfruffen-a',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  final signature = Signature(
    name: 'Ada Lovelace',
    email: 'ada@gitfruffen.dev',
    when: DateTime.utc(2026),
  );
  final commit = Commit(
    oid: GitOid('a' * 40),
    message: 'fix things\n\nbody',
    summary: 'fix things',
    author: signature,
    committer: signature,
    parentOids: [GitOid('b' * 40)],
  );
  const status = RepositoryStatus(
    changes: [],
    currentBranchName: 'main',
    headCommit: null,
  );
  const diff = DiffResult(
    files: [
      DiffFile(
        path: 'lib/a.dart',
        changeType: FileChangeType.modified,
        isBinary: false,
        insertions: 1,
        deletions: 0,
        hunks: [
          DiffHunk(
            header: '@@ -1 +1 @@',
            lines: [
              DiffLine(
                kind: DiffLineKind.context,
                content: 'hello',
                oldLine: 1,
                newLine: 1,
              ),
              DiffLine(kind: DiffLineKind.added, content: 'world', newLine: 2),
            ],
          ),
        ],
      ),
    ],
  );
  final tab = RepositoryTab(
    repository: repository,
    status: status,
    graph: [commit],
    selectedCommitOid: commit.oid,
    commitDiff: diff,
  );

  testWidgets('asks the workspace to open a file diff', (tester) async {
    final bloc = _MockRepositoryBloc();
    OpenFileRequest? opened;
    when(
      () => bloc.state,
    ).thenReturn(RepositoryReady(tabs: [tab], activePath: repository.path));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.add(any())).thenAnswer((_) {});

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<RepositoryBloc>.value(
            value: bloc,
            child: SizedBox(
              width: 380,
              height: 600,
              child: CommitDetailsPanel(
                tab: tab,
                onOpenFile: (file) => opened = file,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('fix things'), findsOneWidget);
    expect(find.textContaining('1 files changed'), findsOneWidget);

    await tester.tap(find.text('lib/a.dart'));
    await tester.pumpAndSettle();

    expect(opened?.file.path, 'lib/a.dart');
    expect(opened?.source, FileDiffSource.commit);
    expect(opened?.commitOid, commit.oid);
  });
}
