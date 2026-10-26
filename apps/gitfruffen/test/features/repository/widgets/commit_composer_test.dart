import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/commit_composer.dart';
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
  final head = Commit(
    oid: GitOid('a' * 40),
    message: 'Old summary\n\nOld body',
    summary: 'Old summary',
    author: Signature(
      name: 'Ada Lovelace',
      email: 'ada@gitfruffen.dev',
      when: DateTime.utc(2026),
    ),
    committer: Signature(
      name: 'Ada Lovelace',
      email: 'ada@gitfruffen.dev',
      when: DateTime.utc(2026),
    ),
    parentOids: const [],
  );
  const status = RepositoryStatus(
    changes: [
      FileChange(
        path: 'lib/a.dart',
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
    status: RepositoryStatus(
      changes: status.changes,
      currentBranchName: status.currentBranchName,
      headCommit: head,
    ),
  );

  testWidgets('submits the summary and prefills amend fields', (tester) async {
    final bloc = _MockRepositoryBloc();
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
              child: CommitComposer(tab: tab),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'new summary');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Commit'));
    await tester.pump();

    final event =
        verify(() => bloc.add(captureAny())).captured.single as CommitSubmitted;
    expect(event.message, 'new summary');

    await tester.tap(find.text('Amend previous commit'));
    await tester.pump();

    final summary = tester.widget<TextField>(find.byType(TextField).first);
    expect(summary.controller!.text, 'Old summary');
  });

  testWidgets('enables amend with zero staged files', (tester) async {
    final amendTab = RepositoryTab(
      repository: repository,
      status: RepositoryStatus(
        changes: const [],
        currentBranchName: 'main',
        headCommit: head,
      ),
    );
    final bloc = _MockRepositoryBloc();
    when(() => bloc.state).thenReturn(
      RepositoryReady(tabs: [amendTab], activePath: repository.path),
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
              child: CommitComposer(tab: amendTab),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    FilledButton commitButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Commit'),
    );
    expect(commitButton().onPressed, isNull);

    await tester.tap(find.text('Amend previous commit'));
    await tester.pump();

    expect(commitButton().onPressed, isNotNull);
    final summary = tester.widget<TextField>(find.byType(TextField).first);
    expect(summary.controller!.text, 'Old summary');
  });
}
