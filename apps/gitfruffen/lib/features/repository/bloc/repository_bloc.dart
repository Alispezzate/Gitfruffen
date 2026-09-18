import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';

/// Owns the lifecycle of every repository opened in a tab.
///
/// It depends only on `GitRepositoryContract` / `WorkspaceRepositoryContract`,
/// keeping the bloc independent from libgit2 and trivially testable.
class RepositoryBloc extends Bloc<RepositoryEvent, RepositoryState> {
  RepositoryBloc({
    required GitRepositoryContract repository,
    required WorkspaceRepositoryContract workspace,
  }) : _repository = repository,
       _workspace = workspace,
       super(const RepositoryInitial()) {
    on<RepositoryOpened>(_onOpened);
    on<RepositoryCloned>(_onCloned);
    on<RepositoryTabSelected>(_onTabSelected);
    on<RepositoryTabClosed>(_onTabClosed);
    on<RepositoryRefreshed>(_onRefreshed);
    on<RepositoryGraphLoadMore>(_onGraphLoadMore);
    on<RepositoryClosed>(_onClosed);
    on<FilesStaged>(_onFilesStaged);
    on<FilesUnstaged>(_onFilesUnstaged);
    on<AllFilesStaged>(_onAllFilesStaged);
    on<AllFilesUnstaged>(_onAllFilesUnstaged);
    on<CommitSubmitted>(_onCommitSubmitted);
    on<BranchCheckedOut>(_onBranchCheckedOut);
    on<BranchCreated>(_onBranchCreated);
    on<BranchDeleted>(_onBranchDeleted);
    on<StashCreated>(_onStashCreated);
    on<StashApplied>(_onStashApplied);
    on<StashPopped>(_onStashPopped);
    on<StashDropped>(_onStashDropped);
    on<WorktreeCreated>(_onWorktreeCreated);
    on<WorktreeRemoved>(_onWorktreeRemoved);
    on<RepositoryPushed>(_onPushed);
    on<RepositoryPulled>(_onPulled);
    on<UndoRequested>(_onUndo);
    on<RedoRequested>(_onRedo);
  }

  final GitRepositoryContract _repository;
  final WorkspaceRepositoryContract _workspace;

  /// Whether the active tab has a HEAD position to step back to.
  bool get canUndo {
    final path = state.activePath;
    return path != null && (_undo[path]?.isNotEmpty ?? false);
  }

  /// Whether the active tab has an undone HEAD position to re-apply.
  bool get canRedo {
    final path = state.activePath;
    return path != null && (_redo[path]?.isNotEmpty ?? false);
  }

  static const int _graphPageSize = 50;

  static const String _zeroOid = '0000000000000000000000000000000000000000';

  /// HEAD positions the user can step back to, per path, most recent last.
  ///
  /// Seeded from the reflog on load and extended before every HEAD-changing
  /// operation. Git has no native redo stack, so undone positions are moved
  /// to [_redo] in memory for the lifetime of the tab.
  final Map<String, List<GitOid>> _undo = {};

  /// HEAD positions the user has undone, per path, most recent last.
  final Map<String, List<GitOid>> _redo = {};

  Future<void> _onOpened(
    RepositoryOpened event,
    Emitter<RepositoryState> emit,
  ) async {
    emit(RepositoryLoading(tabs: state.tabs, activePath: state.activePath));
    try {
      final repo = await _repository.discover(startPath: event.path);
      await _openTab(repo, emit);
    } on GitFailure catch (failure) {
      _emitFailure(failure, emit);
    } on Object catch (error, stackTrace) {
      _emitFailure(
        UnexpectedGitFailure('Unable to open ${event.path}', cause: error),
        emit,
      );
      addError(error, stackTrace);
    }
  }

  Future<void> _onCloned(
    RepositoryCloned event,
    Emitter<RepositoryState> emit,
  ) async {
    emit(RepositoryLoading(tabs: state.tabs, activePath: state.activePath));
    try {
      final repo = await _repository.clone(
        url: event.url,
        localPath: event.localPath,
      );
      await _openTab(repo, emit);
    } on GitFailure catch (failure) {
      _emitFailure(failure, emit);
    } on Object catch (error, stackTrace) {
      _emitFailure(
        UnexpectedGitFailure('Unable to clone ${event.url}', cause: error),
        emit,
      );
      addError(error, stackTrace);
    }
  }

  /// Loads [repository]'s workspace snapshot and makes it the active tab.
  ///
  /// Re-opening an already open repository reuses its tab instead of adding a
  /// duplicate.
  Future<void> _openTab(
    GitRepository repository,
    Emitter<RepositoryState> emit,
  ) async {
    final existing = _existingTab(repository.path);
    if (existing != null) {
      await _repository.dispose(path: repository.path);
      emit(
        RepositoryReady(tabs: state.tabs, activePath: existing.repository.path),
      );
      return;
    }

    await _workspace.rememberRecentRepository(repository);
    final tab = await _loadWorkspace(repository, emit);
    emit(
      RepositoryReady(tabs: [...state.tabs, tab], activePath: repository.path),
    );
  }

  /// Loads status, graph and refs for [repository].
  ///
  /// When [resetHistory] is true the undo stack is reseeded from the reflog,
  /// which happens whenever the workspace is loaded fresh.
  Future<RepositoryTab> _loadWorkspace(
    GitRepository repository,
    Emitter<RepositoryState> emit, {
    bool resetHistory = false,
  }) async {
    final path = repository.path;
    final results = await Future.wait([
      _repository.status(path: path),
      _repository.graph(path: path, limit: _graphPageSize),
      _repository.branches(path: path),
      _repository.tags(path: path),
      _repository.worktrees(path: path),
      _repository.stashes(path: path),
      _repository.reflog(path: path),
    ]);

    final status = results[0] as RepositoryStatus;
    final graph = results[1] as List<Commit>;
    final branches = results[2] as List<Branch>;
    final tags = results[3] as List<Tag>;
    final worktrees = results[4] as List<WorktreeInfo>;
    final stashes = results[5] as List<StashEntry>;
    final reflog = results[6] as List<ReflogEntry>;

    if (resetHistory || !_undo.containsKey(path)) {
      _undo[path] = [
        for (final entry in reflog)
          if (entry.oldOid.value != _zeroOid) entry.oldOid,
      ];
      _redo[path] = [];
    }

    return RepositoryTab(
      repository: repository,
      status: status,
      graph: graph,
      branches: branches,
      tags: tags,
      worktrees: worktrees,
      stashes: stashes,
      hasMoreGraph: graph.length == _graphPageSize,
    );
  }

  void _onTabSelected(
    RepositoryTabSelected event,
    Emitter<RepositoryState> emit,
  ) {
    final tab = _existingTab(event.path);
    if (tab == null || tab.repository.path == state.activePath) {
      return;
    }
    emit(RepositoryReady(tabs: state.tabs, activePath: tab.repository.path));
  }

  Future<void> _onTabClosed(
    RepositoryTabClosed event,
    Emitter<RepositoryState> emit,
  ) async {
    final tabs = state.tabs;
    final index = tabs.indexWhere((tab) => tab.repository.path == event.path);
    if (index == -1) {
      return;
    }

    final wasActive = state.activePath == event.path;
    await _repository.dispose(path: event.path);
    _undo.remove(event.path);
    _redo.remove(event.path);

    final remaining = [...tabs]..removeAt(index);
    if (remaining.isEmpty) {
      emit(const RepositoryInitial());
      return;
    }

    final nextIndex = index >= remaining.length ? remaining.length - 1 : index;
    emit(
      RepositoryReady(
        tabs: remaining,
        activePath: wasActive
            ? remaining[nextIndex].repository.path
            : state.activePath!,
      ),
    );
  }

  Future<void> _onRefreshed(
    RepositoryRefreshed event,
    Emitter<RepositoryState> emit,
  ) async {
    final tab = _resolve(event.path);
    if (tab == null) {
      return;
    }
    try {
      final refreshed = await _loadWorkspace(
        tab.repository,
        emit,
        resetHistory: true,
      );
      _replaceTab(refreshed, emit);
    } on GitFailure catch (failure) {
      _emitFailure(failure, emit);
    }
  }

  Future<void> _onGraphLoadMore(
    RepositoryGraphLoadMore event,
    Emitter<RepositoryState> emit,
  ) async {
    final tab = _resolve(null);
    if (tab == null ||
        !tab.hasMoreGraph ||
        tab.isLoadingMoreGraph ||
        tab.graph.isEmpty) {
      return;
    }
    _replaceTab(tab.copyWith(isLoadingMoreGraph: true), emit);
    try {
      final next = await _repository.graph(
        path: tab.repository.path,
        limit: _graphPageSize,
        from: tab.graph.last.oid,
      );
      _replaceTab(
        tab.copyWith(
          graph: [...tab.graph, ...next],
          hasMoreGraph: next.length == _graphPageSize,
          isLoadingMoreGraph: false,
        ),
        emit,
      );
    } on GitFailure catch (failure) {
      _emitFailure(failure, emit);
    }
  }

  Future<void> _onFilesStaged(
    FilesStaged event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.stage(path: path, paths: event.paths),
  );

  Future<void> _onFilesUnstaged(
    FilesUnstaged event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.unstage(path: path, paths: event.paths),
  );

  Future<void> _onAllFilesStaged(
    AllFilesStaged event,
    Emitter<RepositoryState> emit,
  ) {
    final tab = _resolve(null);
    if (tab == null) {
      return Future<void>.value();
    }
    final paths = [for (final change in tab.status.changes) change.path];
    return _mutate(emit, (path) => _repository.stage(path: path, paths: paths));
  }

  Future<void> _onAllFilesUnstaged(
    AllFilesUnstaged event,
    Emitter<RepositoryState> emit,
  ) {
    final tab = _resolve(null);
    if (tab == null) {
      return Future<void>.value();
    }
    final paths = [for (final change in tab.status.changes) change.path];
    return _mutate(
      emit,
      (path) => _repository.unstage(path: path, paths: paths),
    );
  }

  Future<void> _onCommitSubmitted(
    CommitSubmitted event,
    Emitter<RepositoryState> emit,
  ) {
    final message = event.message.trim();
    if (message.isEmpty) {
      return Future<void>.value();
    }
    return _mutate(
      emit,
      (path) => _repository.commit(path: path, message: message),
      changesHead: true,
    );
  }

  Future<void> _onBranchCheckedOut(
    BranchCheckedOut event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.checkout(path: path, branchName: event.branch),
    changesHead: true,
  );

  Future<void> _onBranchCreated(
    BranchCreated event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.createBranch(
      path: path,
      name: event.name,
      checkout: event.checkout,
    ),
    changesHead: event.checkout,
  );

  Future<void> _onBranchDeleted(
    BranchDeleted event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.deleteBranch(path: path, name: event.name),
  );

  Future<void> _onStashCreated(
    StashCreated event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.stash(path: path, message: event.message),
  );

  Future<void> _onStashApplied(
    StashApplied event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.applyStash(path: path, index: event.index),
  );

  Future<void> _onStashPopped(
    StashPopped event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.popStash(path: path, index: event.index),
  );

  Future<void> _onStashDropped(
    StashDropped event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.dropStash(path: path, index: event.index),
  );

  Future<void> _onWorktreeCreated(
    WorktreeCreated event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.addWorktree(
      path: path,
      name: event.name,
      worktreePath: event.path,
      ref: event.ref,
    ),
  );

  Future<void> _onWorktreeRemoved(
    WorktreeRemoved event,
    Emitter<RepositoryState> emit,
  ) => _mutate(
    emit,
    (path) => _repository.removeWorktree(path: path, name: event.name),
  );

  Future<void> _onPushed(
    RepositoryPushed event,
    Emitter<RepositoryState> emit,
  ) => _mutate(emit, (path) => _repository.push(path: path));

  Future<void> _onPulled(
    RepositoryPulled event,
    Emitter<RepositoryState> emit,
  ) => _mutate(emit, (path) => _repository.pull(path: path));

  Future<void> _onUndo(
    UndoRequested event,
    Emitter<RepositoryState> emit,
  ) async {
    final tab = _resolve(null);
    if (tab == null) {
      return;
    }
    final path = tab.repository.path;
    final stack = _undo[path] ?? const <GitOid>[];
    final current = tab.status.headCommit?.oid;
    if (stack.isEmpty || current == null) {
      return;
    }
    final target = stack.last;
    await _mutate(
      emit,
      (repoPath) => _repository.resetTo(
        path: repoPath,
        oid: target.value,
        mode: GitResetMode.mixed,
      ),
      onSuccess: () {
        _undo[path] = stack.sublist(0, stack.length - 1);
        _redo[path] = [...?_redo[path], current];
      },
    );
  }

  Future<void> _onRedo(
    RedoRequested event,
    Emitter<RepositoryState> emit,
  ) async {
    final tab = _resolve(null);
    if (tab == null) {
      return;
    }
    final path = tab.repository.path;
    final stack = _redo[path] ?? const <GitOid>[];
    if (stack.isEmpty) {
      return;
    }
    final target = stack.last;
    await _mutate(
      emit,
      (repoPath) => _repository.resetTo(
        path: repoPath,
        oid: target.value,
        mode: GitResetMode.mixed,
      ),
      onSuccess: () {
        _redo[path] = stack.sublist(0, stack.length - 1);
        _undo[path] = [...?_undo[path], target];
      },
    );
  }

  Future<void> _onClosed(
    RepositoryClosed event,
    Emitter<RepositoryState> emit,
  ) async {
    final path = state.activePath;
    if (path == null) {
      return;
    }
    await _onTabClosed(RepositoryTabClosed(path), emit);
  }

  /// Runs [operation] against the active repository, toggling the busy flag and
  /// reloading the workspace on success.
  ///
  /// When [changesHead] is true the current HEAD is pushed onto the undo stack
  /// and the redo stack is cleared before the operation runs.
  Future<void> _mutate(
    Emitter<RepositoryState> emit,
    Future<void> Function(String path) operation, {
    bool changesHead = false,
    void Function()? onSuccess,
  }) async {
    final tab = _resolve(null);
    final ready = state;
    if (tab == null || ready is! RepositoryReady) {
      return;
    }
    final path = tab.repository.path;
    if (changesHead) {
      final current = tab.status.headCommit?.oid;
      if (current != null) {
        _undo[path] = [...?_undo[path], current];
      }
      _redo[path] = [];
    }
    emit(ready.copyWith(isBusy: true));
    try {
      await operation(path);
      final refreshed = await _loadWorkspace(tab.repository, emit);
      _replaceTab(refreshed, emit);
      onSuccess?.call();
    } on GitFailure catch (failure) {
      _emitFailure(failure, emit, ready: ready);
    } on Object catch (error, stackTrace) {
      _emitFailure(
        UnexpectedGitFailure('$error', cause: error),
        emit,
        ready: ready,
      );
      addError(error, stackTrace);
    }
  }

  RepositoryTab? _resolve(String? path) {
    final resolved = path ?? state.activePath;
    return resolved == null ? null : _existingTab(resolved);
  }

  RepositoryTab? _existingTab(String path) {
    for (final tab in state.tabs) {
      if (tab.repository.path == path) {
        return tab;
      }
    }
    return null;
  }

  /// Replaces the tab matching [tab]'s path, preserving tab order and the
  /// active path.
  void _replaceTab(RepositoryTab tab, Emitter<RepositoryState> emit) {
    final ready = state;
    final activePath = ready.activePath;
    if (ready is! RepositoryReady || activePath == null) {
      return;
    }
    emit(
      ready.copyWith(
        tabs: [
          for (final current in ready.tabs)
            if (current.repository.path == tab.repository.path)
              tab
            else
              current,
        ],
        isBusy: false,
      ),
    );
  }

  /// Surfaces [failure] without discarding open tabs; falls back to the
  /// terminal [RepositoryError] when there is nothing to keep working in.
  void _emitFailure(
    GitFailure failure,
    Emitter<RepositoryState> emit, {
    RepositoryReady? ready,
  }) {
    final tabs = ready?.tabs ?? state.tabs;
    final activePath = ready?.activePath ?? state.activePath;
    if (tabs.isEmpty || activePath == null) {
      emit(RepositoryError(failure));
      return;
    }
    emit(RepositoryReady(tabs: tabs, activePath: activePath, failure: failure));
  }
}
