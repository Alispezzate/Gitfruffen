import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

class _MockWorkspaceRepository extends Mock
    implements WorkspaceRepositoryContract {}

class _FakeGitRepository extends Fake implements GitRepository {}

void main() {
  late _MockGitRepository repository;
  late _MockWorkspaceRepository workspace;

  setUpAll(() {
    registerFallbackValue(_FakeGitRepository());
  });

  const path = '/tmp/gitfruffen';
  const gitRepository = GitRepository(
    path: path,
    name: 'gitfruffen',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const status = RepositoryStatus(
    changes: [],
    currentBranchName: 'main',
    headCommit: null,
  );

  setUp(() {
    repository = _MockGitRepository();
    workspace = _MockWorkspaceRepository();
    when(
      () => workspace.rememberRecentRepository(any()),
    ).thenAnswer((_) async {});
    when(
      () => repository.dispose(path: any(named: 'path')),
    ).thenAnswer((_) async {});
  });

  blocTest<RepositoryBloc, RepositoryState>(
    'emits Loading then Ready when a repository opens successfully',
    setUp: () {
      when(
        () => repository.open(path: any(named: 'path')),
      ).thenAnswer((_) async => gitRepository);
      when(
        () => repository.status(path: any(named: 'path')),
      ).thenAnswer((_) async => status);
    },
    build: () => RepositoryBloc(repository: repository, workspace: workspace),
    act: (bloc) => bloc.add(const RepositoryOpened(path)),
    expect: () => [
      const RepositoryLoading(),
      const RepositoryReady(repository: gitRepository, status: status),
    ],
    verify: (_) {
      verify(() => workspace.rememberRecentRepository(gitRepository)).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'emits Loading then Error when opening fails',
    setUp: () {
      when(
        () => repository.open(path: any(named: 'path')),
      ).thenThrow(const RepositoryNotFoundFailure('not a repository'));
    },
    build: () => RepositoryBloc(repository: repository, workspace: workspace),
    act: (bloc) => bloc.add(const RepositoryOpened(path)),
    expect: () => [
      const RepositoryLoading(),
      const RepositoryError(RepositoryNotFoundFailure('not a repository')),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryRefreshed is a no-op when no repository is open',
    build: () => RepositoryBloc(repository: repository, workspace: workspace),
    act: (bloc) => bloc.add(const RepositoryRefreshed()),
    expect: () => const <RepositoryState>[],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryClosed disposes the repository and resets state',
    setUp: () {
      when(
        () => repository.open(path: any(named: 'path')),
      ).thenAnswer((_) async => gitRepository);
      when(
        () => repository.status(path: any(named: 'path')),
      ).thenAnswer((_) async => status);
    },
    build: () => RepositoryBloc(repository: repository, workspace: workspace),
    act: (bloc) async {
      bloc.add(const RepositoryOpened(path));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RepositoryClosed());
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) {
      verify(() => repository.dispose(path: path)).called(1);
    },
  );
}
