import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'repository_event.dart';
import 'repository_state.dart';

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
    on<RepositoryClosed>(_onClosed);
  }

  final GitRepositoryContract _repository;
  final WorkspaceRepositoryContract _workspace;

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

  /// Loads [repository]'s status and makes it the active tab.
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
    final status = await _repository.status(path: repository.path);
    final tab = RepositoryTab(repository: repository, status: status);
    emit(
      RepositoryReady(tabs: [...state.tabs, tab], activePath: repository.path),
    );
  }

  void _onTabSelected(
    RepositoryTabSelected event,
    Emitter<RepositoryState> emit,
  ) {
    final tab = _existingTab(event.path);
    if (tab == null || tab.repository.path == state.activePath) return;
    emit(RepositoryReady(tabs: state.tabs, activePath: tab.repository.path));
  }

  Future<void> _onTabClosed(
    RepositoryTabClosed event,
    Emitter<RepositoryState> emit,
  ) async {
    final tabs = state.tabs;
    final index = tabs.indexWhere((tab) => tab.repository.path == event.path);
    if (index == -1) return;

    final wasActive = state.activePath == event.path;
    await _repository.dispose(path: event.path);

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
    final path = event.path ?? state.activePath;
    final tab = path == null ? null : _existingTab(path);
    if (tab == null) return;
    try {
      final status = await _repository.status(path: tab.repository.path);
      emit(
        RepositoryReady(
          tabs: [
            for (final current in state.tabs)
              if (current.repository.path == tab.repository.path)
                RepositoryTab(repository: current.repository, status: status)
              else
                current,
          ],
          activePath: state.activePath!,
        ),
      );
    } on GitFailure catch (failure) {
      _emitFailure(failure, emit);
    }
  }

  Future<void> _onClosed(
    RepositoryClosed event,
    Emitter<RepositoryState> emit,
  ) async {
    final path = state.activePath;
    if (path == null) return;
    await _onTabClosed(RepositoryTabClosed(path), emit);
  }

  RepositoryTab? _existingTab(String path) {
    for (final tab in state.tabs) {
      if (tab.repository.path == path) return tab;
    }
    return null;
  }

  /// Surfaces [failure] without discarding open tabs; falls back to the
  /// terminal [RepositoryError] when there is nothing to keep working in.
  void _emitFailure(GitFailure failure, Emitter<RepositoryState> emit) {
    final tabs = state.tabs;
    final activePath = state.activePath;
    if (tabs.isEmpty || activePath == null) {
      emit(RepositoryError(failure));
      return;
    }
    emit(RepositoryReady(tabs: tabs, activePath: activePath, failure: failure));
  }
}
