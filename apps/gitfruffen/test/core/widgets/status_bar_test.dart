import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/core/widgets/status_bar.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

class _MockWorkspaceRepository extends Mock
    implements WorkspaceRepositoryContract {}

void main() {
  late _MockGitRepository repository;
  late _MockWorkspaceRepository workspace;

  const pathA = '/tmp/gitfruffen-a';
  const repoA = GitRepository(
    path: pathA,
    name: 'gitfruffen-a',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const status = RepositoryStatus(
    changes: [
      FileChange(
        path: 'staged.dart',
        type: FileChangeType.modified,
        staged: true,
        unstaged: false,
        conflicted: false,
      ),
      FileChange(
        path: 'unstaged.dart',
        type: FileChangeType.modified,
        staged: false,
        unstaged: true,
        conflicted: false,
      ),
      FileChange(
        path: 'conflicted.dart',
        type: FileChangeType.conflicted,
        staged: true,
        unstaged: true,
        conflicted: true,
      ),
    ],
    currentBranchName: 'feature/x',
    headCommit: null,
  );
  const head = Branch(
    name: 'feature/x',
    kind: BranchKind.local,
    isHead: true,
    ahead: 2,
    behind: 1,
  );

  setUpAll(() {
    registerFallbackValue(
      const GitRepository(
        path: '',
        name: '',
        isBare: false,
        isHeadDetached: false,
        isUnborn: false,
      ),
    );
  });

  setUp(() {
    repository = _MockGitRepository();
    workspace = _MockWorkspaceRepository();
    when(
      () => workspace.rememberRecentRepository(any()),
    ).thenAnswer((_) async {});
    when(
      () => repository.discover(startPath: any(named: 'startPath')),
    ).thenAnswer((_) async => repoA);
    when(
      () => repository.status(path: any(named: 'path')),
    ).thenAnswer((_) async => status);
    when(
      () => repository.graph(
        path: any(named: 'path'),
        limit: any(named: 'limit'),
        from: any(named: 'from'),
      ),
    ).thenAnswer((_) async => const <Commit>[]);
    when(
      () => repository.branches(path: any(named: 'path')),
    ).thenAnswer((_) async => const [head]);
    when(
      () => repository.tags(path: any(named: 'path')),
    ).thenAnswer((_) async => const <Tag>[]);
    when(
      () => repository.worktrees(path: any(named: 'path')),
    ).thenAnswer((_) async => const <WorktreeInfo>[]);
    when(
      () => repository.stashes(path: any(named: 'path')),
    ).thenAnswer((_) async => const <StashEntry>[]);
    when(
      () => repository.reflog(path: any(named: 'path')),
    ).thenAnswer((_) async => const <ReflogEntry>[]);
    when(
      () => repository.diffWorkingTree(
        path: any(named: 'path'),
        staged: any(named: 'staged'),
      ),
    ).thenAnswer((_) async => const DiffResult(files: []));
    when(
      () => repository.dispose(path: any(named: 'path')),
    ).thenAnswer((_) async {});
  });

  testWidgets('summarises the active repository', (tester) async {
    await tester.pumpWidget(
      BlocProvider<RepositoryBloc>(
        create: (_) =>
            RepositoryBloc(repository: repository, workspace: workspace),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StatusBar()),
        ),
      ),
    );

    tester
        .element(find.byType(StatusBar))
        .read<RepositoryBloc>()
        .add(const RepositoryOpened(pathA));
    await tester.pumpAndSettle();

    expect(find.text('feature/x'), findsOneWidget);
    expect(find.text('↑2 ↓1'), findsOneWidget);
    expect(find.text('Staged 1'), findsOneWidget);
    expect(find.text('Unstaged 1'), findsOneWidget);
    expect(find.text('Conflicted 1'), findsOneWidget);
    expect(find.text(pathA), findsOneWidget);
  });
}
