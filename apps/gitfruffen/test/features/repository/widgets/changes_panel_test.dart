import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/changes_panel.dart';
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
  const status = RepositoryStatus(
    changes: [
      FileChange(
        path: 'lib/unstaged.dart',
        type: FileChangeType.modified,
        staged: false,
        unstaged: true,
        conflicted: false,
      ),
      FileChange(
        path: 'lib/staged.dart',
        type: FileChangeType.added,
        staged: true,
        unstaged: false,
        conflicted: false,
      ),
    ],
    currentBranchName: 'main',
    headCommit: null,
  );
  const tab = RepositoryTab(
    repository: repository,
    status: status,
    stagedDiff: DiffResult(
      files: [
        DiffFile(
          path: 'lib/staged.dart',
          changeType: FileChangeType.added,
          isBinary: false,
          insertions: 3,
          deletions: 0,
        ),
      ],
    ),
    unstagedDiff: DiffResult(
      files: [
        DiffFile(
          path: 'lib/unstaged.dart',
          changeType: FileChangeType.modified,
          isBinary: false,
          insertions: 2,
          deletions: 1,
        ),
      ],
    ),
  );

  testWidgets('shows both sections and stages a single file', (tester) async {
    final bloc = _MockRepositoryBloc();
    OpenFileRequest? opened;
    when(() => bloc.state).thenReturn(
      RepositoryReady(tabs: const [tab], activePath: repository.path),
    );
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
              child: ChangesPanel(
                tab: tab,
                onOpenFile: (file) => opened = file,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 file changes on main'), findsOneWidget);
    expect(find.textContaining('Unstaged Files'), findsOneWidget);
    expect(find.textContaining('Staged Files'), findsOneWidget);

    await tester.tap(find.text('lib/unstaged.dart'));
    await tester.pump();
    expect(opened?.file.path, 'lib/unstaged.dart');
    expect(opened?.source, FileDiffSource.unstaged);

    await tester.tap(find.byTooltip('Stage file').first);
    await tester.pump();

    final event =
        verify(() => bloc.add(captureAny())).captured.single as FilesStaged;
    expect(event.paths, ['lib/unstaged.dart']);
  });
}
