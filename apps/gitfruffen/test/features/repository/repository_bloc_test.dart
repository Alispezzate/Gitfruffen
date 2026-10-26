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
      const GitOid('0000000000000000000000000000000000000000'),
    );
    registerFallbackValue(GitResetMode.hard);
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
  const commitDiff = DiffResult(
    files: [
      DiffFile(
        path: 'a.dart',
        changeType: FileChangeType.modified,
        isBinary: false,
        insertions: 1,
        deletions: 0,
      ),
    ],
  );

  Commit commit(String sha, {List<String> parents = const []}) => Commit(
    oid: GitOid(sha),
    message: 'subject\n',
    summary: 'subject',
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
    parentOids: [for (final parent in parents) GitOid(parent)],
  );

  final graph = List.generate(50, (i) => commit('${i + 1}'.padLeft(40, '0')));

  RepositoryTab tab({
    GitRepository repository = repoA,
    RepositoryStatus status = status,
    List<Commit> graph = const [],
    List<Branch> branches = const [],
    bool hasMoreGraph = false,
  }) => RepositoryTab(
    repository: repository,
    status: status,
    graph: graph,
    branches: branches,
    hasMoreGraph: hasMoreGraph,
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
    ).thenAnswer((_) async => const <Branch>[]);
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
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(() => workspace.rememberRecentRepository(repoA)).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'initialises a repository and opens it in a tab',
    setUp: () {
      when(() => repository.init(path: pathA)).thenAnswer((_) async => repoA);
    },
    build: build,
    act: (bloc) => bloc.add(const RepositoryInitialized(pathA)),
    expect: () => [
      const RepositoryLoading(),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(() => repository.init(path: pathA)).called(1);
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
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryOpened(pathB)),
    expect: () => [
      const RepositoryLoading(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
      const RepositoryReady(
        tabs: [
          RepositoryTab(repository: repoA, status: status),
          RepositoryTab(repository: repoB, status: status),
        ],
        activePath: pathB,
      ),
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
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryOpened(pathA)),
    expect: () => [
      const RepositoryLoading(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
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
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryOpened(pathB)),
    expect: () => [
      const RepositoryLoading(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
        failure: RepositoryNotFoundFailure('not a repository'),
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryTabSelected activates the matching tab',
    build: build,
    seed: () => const RepositoryReady(
      tabs: [
        RepositoryTab(repository: repoA, status: status),
        RepositoryTab(repository: repoB, status: status),
      ],
      activePath: pathB,
    ),
    act: (bloc) => bloc.add(const RepositoryTabSelected(pathA)),
    expect: () => [
      const RepositoryReady(
        tabs: [
          RepositoryTab(repository: repoA, status: status),
          RepositoryTab(repository: repoB, status: status),
        ],
        activePath: pathA,
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryTabSelected is a no-op for an unknown or active tab',
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryTabSelected(pathA)),
    expect: () => const <RepositoryState>[],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'closing the active tab activates its neighbour and disposes it',
    build: build,
    seed: () => const RepositoryReady(
      tabs: [
        RepositoryTab(repository: repoA, status: status),
        RepositoryTab(repository: repoB, status: status),
      ],
      activePath: pathB,
    ),
    act: (bloc) => bloc.add(const RepositoryTabClosed(pathB)),
    expect: () => [
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(() => repository.dispose(path: pathB)).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'closing the last tab returns to the initial state',
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
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
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: staleStatus)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryRefreshed()),
    expect: () => [
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'staging files toggles busy then reloads the workspace',
    setUp: () {
      when(
        () => repository.stage(
          path: pathA,
          paths: any(named: 'paths'),
        ),
      ).thenAnswer((_) async {});
    },
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const FilesStaged(['a.dart'])),
    expect: () => [
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
        isBusy: true,
      ),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(() => repository.stage(path: pathA, paths: ['a.dart'])).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'creating a commit passes the trimmed message',
    setUp: () {
      when(
        () => repository.commit(
          path: pathA,
          message: any(named: 'message'),
          amend: any(named: 'amend'),
        ),
      ).thenAnswer((_) async => commit('a' * 40));
    },
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const CommitSubmitted('  hello  ')),
    expect: () => [
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
        isBusy: true,
      ),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(() => repository.commit(path: pathA, message: 'hello')).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'CommitSelected emits the loading selection then the commit diff',
    setUp: () {
      when(
        () => repository.diffCommit(
          path: pathA,
          oid: any(named: 'oid'),
        ),
      ).thenAnswer((_) async => commitDiff);
    },
    build: build,
    seed: () => RepositoryReady(
      tabs: [
        tab(graph: [commit('c' * 40)]),
      ],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(CommitSelected(GitOid('c' * 40))),
    expect: () => [
      RepositoryReady(
        tabs: [
          tab(graph: [commit('c' * 40)]).copyWith(
            selectedCommitOid: GitOid('c' * 40),
            isLoadingCommitDiff: true,
          ),
        ],
        activePath: pathA,
      ),
      RepositoryReady(
        tabs: [
          tab(graph: [commit('c' * 40)]).copyWith(
            selectedCommitOid: GitOid('c' * 40),
            commitDiff: commitDiff,
            isLoadingCommitDiff: false,
          ),
        ],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(
        () => repository.diffCommit(path: pathA, oid: GitOid('c' * 40)),
      ).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'CommitSelectionCleared clears the selected commit and its diff',
    build: build,
    seed: () => RepositoryReady(
      tabs: [
        tab(
          graph: [commit('c' * 40)],
        ).copyWith(selectedCommitOid: GitOid('c' * 40), commitDiff: commitDiff),
      ],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const CommitSelectionCleared()),
    expect: () => [
      RepositoryReady(
        tabs: [
          tab(graph: [commit('c' * 40)]),
        ],
        activePath: pathA,
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'creating a commit forwards amend',
    setUp: () {
      when(
        () => repository.commit(
          path: pathA,
          message: any(named: 'message'),
          amend: any(named: 'amend'),
        ),
      ).thenAnswer((_) async => commit('a' * 40));
    },
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const CommitSubmitted('hello', amend: true)),
    expect: () => [
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
        isBusy: true,
      ),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(
        () => repository.commit(path: pathA, message: 'hello', amend: true),
      ).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'creating a commit with a blank message is a no-op',
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const CommitSubmitted('   ')),
    expect: () => const <RepositoryState>[],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'checkout is applied through the repository contract',
    setUp: () {
      when(
        () => repository.checkout(path: pathA, branchName: 'develop'),
      ).thenAnswer((_) async {});
    },
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const BranchCheckedOut('develop')),
    expect: () => [
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
        isBusy: true,
      ),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    ],
    verify: (_) {
      verify(
        () => repository.checkout(path: pathA, branchName: 'develop'),
      ).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'a failing mutation surfaces the failure and keeps the tabs',
    setUp: () {
      when(
        () => repository.push(path: any(named: 'path')),
      ).thenThrow(const NetworkFailure('offline'));
    },
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryPushed()),
    expect: () => [
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
        isBusy: true,
      ),
      const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
        failure: NetworkFailure('offline'),
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'loading more appends the next graph page',
    setUp: () {
      when(
        () => repository.graph(path: pathA, limit: 50, from: graph.last.oid),
      ).thenAnswer((_) async => graph.take(5).toList());
    },
    build: build,
    seed: () => RepositoryReady(
      tabs: [tab(graph: graph, hasMoreGraph: true)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryGraphLoadMore()),
    expect: () => [
      RepositoryReady(
        tabs: [
          tab(
            graph: graph,
            hasMoreGraph: true,
          ).copyWith(isLoadingMoreGraph: true),
        ],
        activePath: pathA,
      ),
      RepositoryReady(
        tabs: [
          tab(graph: [...graph, ...graph.take(5)]),
        ],
        activePath: pathA,
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'RepositoryClosed closes the active tab',
    build: build,
    seed: () => const RepositoryReady(
      tabs: [RepositoryTab(repository: repoA, status: status)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryClosed()),
    expect: () => [const RepositoryInitial()],
    verify: (_) {
      verify(() => repository.dispose(path: pathA)).called(1);
    },
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'a failing graph load-more clears the loading flag and surfaces the failure',
    setUp: () {
      when(
        () => repository.graph(path: pathA, limit: 50, from: graph.last.oid),
      ).thenThrow(const NetworkFailure('offline'));
    },
    build: build,
    seed: () => RepositoryReady(
      tabs: [tab(graph: graph, hasMoreGraph: true)],
      activePath: pathA,
    ),
    act: (bloc) => bloc.add(const RepositoryGraphLoadMore()),
    expect: () => [
      RepositoryReady(
        tabs: [
          tab(
            graph: graph,
            hasMoreGraph: true,
          ).copyWith(isLoadingMoreGraph: true),
        ],
        activePath: pathA,
      ),
      RepositoryReady(
        tabs: [tab(graph: graph, hasMoreGraph: true)],
        activePath: pathA,
      ),
      RepositoryReady(
        tabs: [tab(graph: graph, hasMoreGraph: true)],
        activePath: pathA,
        failure: const NetworkFailure('offline'),
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'commit selection preserves the busy lock',
    setUp: () {
      when(
        () => repository.diffCommit(
          path: pathA,
          oid: any(named: 'oid'),
        ),
      ).thenAnswer((_) async => commitDiff);
    },
    build: build,
    seed: () => RepositoryReady(
      tabs: [
        tab(graph: [commit('c' * 40)]),
      ],
      activePath: pathA,
      isBusy: true,
    ),
    act: (bloc) => bloc.add(CommitSelected(GitOid('c' * 40))),
    expect: () => [
      RepositoryReady(
        tabs: [
          tab(graph: [commit('c' * 40)]).copyWith(
            selectedCommitOid: GitOid('c' * 40),
            isLoadingCommitDiff: true,
          ),
        ],
        activePath: pathA,
        isBusy: true,
      ),
      RepositoryReady(
        tabs: [
          tab(graph: [commit('c' * 40)]).copyWith(
            selectedCommitOid: GitOid('c' * 40),
            commitDiff: commitDiff,
            isLoadingCommitDiff: false,
          ),
        ],
        activePath: pathA,
        isBusy: true,
      ),
    ],
  );

  blocTest<RepositoryBloc, RepositoryState>(
    'undo resets to the most recent previous HEAD from the reflog',
    setUp: () {
      final signature = Signature(
        name: 'Ada Lovelace',
        email: 'ada@gitfruffen.dev',
        when: DateTime.utc(2026),
      );
      final headStatus = RepositoryStatus(
        changes: const [],
        currentBranchName: 'main',
        headCommit: commit('f' * 40),
      );
      when(
        () => repository.discover(startPath: pathA),
      ).thenAnswer((_) async => repoA);
      when(
        () => repository.status(path: pathA),
      ).thenAnswer((_) async => headStatus);
      when(() => repository.reflog(path: pathA)).thenAnswer(
        (_) async => [
          ReflogEntry(
            oldOid: GitOid('b' * 40),
            newOid: GitOid('f' * 40),
            message: 'commit',
            committer: signature,
          ),
          ReflogEntry(
            oldOid: GitOid('a' * 40),
            newOid: GitOid('b' * 40),
            message: 'commit',
            committer: signature,
          ),
        ],
      );
      when(
        () => repository.resetTo(
          path: pathA,
          oid: any(named: 'oid'),
          mode: any(named: 'mode'),
        ),
      ).thenAnswer((_) async {});
    },
    build: build,
    act: (bloc) async {
      final ready = bloc.stream.firstWhere((state) => state is RepositoryReady);
      bloc.add(const RepositoryOpened(pathA));
      await ready;
      bloc.add(const UndoRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (_) {
      verify(
        () => repository.resetTo(
          path: pathA,
          oid: 'b' * 40,
          mode: GitResetMode.mixed,
        ),
      ).called(1);
    },
  );
}
