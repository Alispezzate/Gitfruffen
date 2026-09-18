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

void main() {
  late _MockGitRepository repository;
  late _MockWorkspaceRepository workspace;

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

  const pathA = '/tmp/gitfruffen-a';
  const pathB = '/tmp/gitfruffen-b';
  const repoA = GitRepository(
    path: pathA,
    name: 'gitfruffen-a',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const repoB = GitRepository(
    path: pathB,
    name: 'gitfruffen-b',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const status = RepositoryStatus(
    changes: [],
    currentBranchName: 'main',
    headCommit: null,
  );
  const staleStatus = RepositoryStatus(
    changes: [],
    currentBranchName: 'stale',
    headCommit: null,
  );
  const tabA = RepositoryTab(repository: repoA, status: status);
  const tabB = RepositoryTab(repository: repoB, status: status);
  const staleTabA = RepositoryTab(repository: repoA, status: staleStatus);

  setUp(() {
    repository = _MockGitRepository();
    workspace = _MockWorkspaceRepository();
    when(
      () => workspace.rememberRecentRepository(any()),
    ).thenAnswer((_) async {});
    when(
      () => repository.dispose(path: any(named: 'path')),
    ).thenAnswer((_) async {});
    when(
      () => repository.status(path: any(named: 'path')),
    ).thenAnswer((_) async => status);
  });

  RepositoryBloc build() =>
      RepositoryBloc(repository: repository, workspace: workspace);

  blocTest<RepositoryBloc, RepositoryState>(
    'emits Loading then Ready with one tab when a repository opens',
    setUp: () {
      when(
        () => repository.discover(startPath: pathA),
      ).thenAnswer((_) async => repoA);
    },
    build: build,
    act: (bloc) => bloc.add(const RepositoryOpened(pathA)),
    expect: () => [
      const RepositoryLoading(),
      const RepositoryReady(tabs: [tabA], activePath: pathA),
    ],
    verify: (_) {
      verify(() => workspace.rememberRecentRepository(repoA)).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'opening a second repository appends a tab and activates it',
    setUp: () {
      when(
        () => repository.discover(startPath: pathB),
      ).thenAnswer((_) async => repoB);
    },
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA], activePath: pathA),
    act: (bloc) => bloc.add(const RepositoryOpened(pathB)),
    expect: () => [
      const RepositoryLoading(tabs: [tabA], activePath: pathA),
      const RepositoryReady(tabs: [tabA, tabB], activePath: pathB),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    're-opening an open repository does not duplicate its tab',
    setUp: () {
      when(
        () => repository.discover(startPath: pathA),
      ).thenAnswer((_) async => repoA);
    },
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA], activePath: pathA),
    act: (bloc) => bloc.add(const RepositoryOpened(pathA)),
    expect: () => [
      const RepositoryLoading(tabs: [tabA], activePath: pathA),
      const RepositoryReady(tabs: [tabA], activePath: pathA),
    ],
    verify: (_) {
      verify(() => repository.dispose(path: pathA)).called(1);
      verifyNever(() => workspace.rememberRecentRepository(any()));
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'emits Loading then Error when opening fails with no tabs open',
    setUp: () {
      when(
        () => repository.discover(startPath: pathA),
      ).thenThrow(const RepositoryNotFoundFailure('not a repository'));
    },
    build: build,
    act: (bloc) => bloc.add(const RepositoryOpened(pathA)),
    expect: () => [
      const RepositoryLoading(),
      const RepositoryError(RepositoryNotFoundFailure('not a repository')),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'a failed open keeps the existing tabs usable',
    setUp: () {
      when(
        () => repository.discover(startPath: pathB),
      ).thenThrow(const RepositoryNotFoundFailure('not a repository'));
    },
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA], activePath: pathA),
    act: (bloc) => bloc.add(const RepositoryOpened(pathB)),
    expect: () => [
      const RepositoryLoading(tabs: [tabA], activePath: pathA),
      const RepositoryReady(
        tabs: [tabA],
        activePath: pathA,
        failure: RepositoryNotFoundFailure('not a repository'),
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryTabSelected activates the matching tab',
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA, tabB], activePath: pathB),
    act: (bloc) => bloc.add(const RepositoryTabSelected(pathA)),
    expect: () => [
      const RepositoryReady(tabs: [tabA, tabB], activePath: pathA),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryTabSelected is a no-op for an unknown or active tab',
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA], activePath: pathA),
    act: (bloc) => bloc.add(const RepositoryTabSelected(pathA)),
    expect: () => const <RepositoryState>[],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'closing the active tab activates its neighbour and disposes it',
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA, tabB], activePath: pathB),
    act: (bloc) => bloc.add(const RepositoryTabClosed(pathB)),
    expect: () => [
      const RepositoryReady(tabs: [tabA], activePath: pathA),
    ],
    verify: (_) {
      verify(() => repository.dispose(path: pathB)).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'closing a background tab keeps the active one selected',
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA, tabB], activePath: pathB),
    act: (bloc) => bloc.add(const RepositoryTabClosed(pathA)),
    expect: () => [
      const RepositoryReady(tabs: [tabB], activePath: pathB),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'closing the last tab returns to the initial state',
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA], activePath: pathA),
    act: (bloc) => bloc.add(const RepositoryTabClosed(pathA)),
    expect: () => [const RepositoryInitial()],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryRefreshed is a no-op when no repository is open',
    build: build,
    act: (bloc) => bloc.add(const RepositoryRefreshed()),
    expect: () => const <RepositoryState>[],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryRefreshed reloads the active tab status',
    build: build,
    seed: () => const RepositoryReady(tabs: [staleTabA], activePath: pathA),
    act: (bloc) => bloc.add(const RepositoryRefreshed()),
    expect: () => [
      const RepositoryReady(tabs: [tabA], activePath: pathA),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryClosed closes the active tab',
    build: build,
    seed: () => const RepositoryReady(tabs: [tabA], activePath: pathA),
    act: (bloc) => bloc.add(const RepositoryClosed()),
    expect: () => [const RepositoryInitial()],
    verify: (_) {
      verify(() => repository.dispose(path: pathA)).called(1);
    },
  );
}
