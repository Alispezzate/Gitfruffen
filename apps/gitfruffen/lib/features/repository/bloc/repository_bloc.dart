import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'repository_event.dart';
import 'repository_state.dart';

/// Owns the lifecycle of the currently open repository.
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
    on<RepositoryRefreshed>(_onRefreshed);
    on<RepositoryClosed>(_onClosed);
  }

  final GitRepositoryContract _repository;
  final WorkspaceRepositoryContract _workspace;

  Future<void> _onOpened(
    RepositoryOpened event,
    Emitter<RepositoryState> emit,
  ) async {
    emit(const RepositoryLoading());
    try {
      final repo = await _repository.open(path: event.path);
      await _workspace.rememberRecentRepository(repo);
      final status = await _repository.status(path: repo.path);
      emit(RepositoryReady(repository: repo, status: status));
    } on GitFailure catch (failure) {
      emit(RepositoryError(failure));
    } on Object catch (error, stackTrace) {
      emit(
        RepositoryError(
          UnexpectedGitFailure('Unable to open ${event.path}', cause: error),
        ),
      );
      addError(error, stackTrace);
    }
  }

  Future<void> _onCloned(
    RepositoryCloned event,
    Emitter<RepositoryState> emit,
  ) async {
    emit(const RepositoryLoading());
    try {
      final repo = await _repository.clone(
        url: event.url,
        localPath: event.localPath,
      );
      await _workspace.rememberRecentRepository(repo);
      final status = await _repository.status(path: repo.path);
      emit(RepositoryReady(repository: repo, status: status));
    } on GitFailure catch (failure) {
      emit(RepositoryError(failure));
    } on Object catch (error, stackTrace) {
      emit(
        RepositoryError(
          UnexpectedGitFailure('Unable to clone ${event.url}', cause: error),
        ),
      );
      addError(error, stackTrace);
    }
  }

  Future<void> _onRefreshed(
    RepositoryRefreshed event,
    Emitter<RepositoryState> emit,
  ) async {
    final current = state;
    if (current is! RepositoryReady) return;
    try {
      final status = await _repository.status(path: current.repository.path);
      emit(RepositoryReady(repository: current.repository, status: status));
    } on GitFailure catch (failure) {
      emit(RepositoryError(failure));
    }
  }

  Future<void> _onClosed(
    RepositoryClosed event,
    Emitter<RepositoryState> emit,
  ) async {
    final current = state;
    if (current is RepositoryReady) {
      await _repository.dispose(path: current.repository.path);
    }
    emit(const RepositoryInitial());
  }
}
