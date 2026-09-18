import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/features/history/bloc/history_event.dart';
import 'package:gitfruffen/features/history/bloc/history_state.dart';

/// Loads the commit log of the currently open repository page by page.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required GitRepositoryContract repository})
    : _repository = repository,
      super(const HistoryInitial()) {
    on<HistoryLoaded>(_onLoaded);
    on<HistoryLoadMore>(_onLoadMore);
  }

  final GitRepositoryContract _repository;

  int _limit = 50;

  Future<void> _onLoaded(
    HistoryLoaded event,
    Emitter<HistoryState> emit,
  ) async {
    _limit = event.limit;
    emit(const HistoryLoading());
    try {
      final commits = await _repository.log(path: event.path, limit: _limit);
      emit(
        HistoryReady(
          commits,
          path: event.path,
          hasMore: commits.length == _limit,
        ),
      );
    } on GitFailure catch (failure) {
      emit(HistoryError(failure));
    }
  }

  Future<void> _onLoadMore(
    HistoryLoadMore event,
    Emitter<HistoryState> emit,
  ) async {
    final current = state;
    if (current is! HistoryReady) {
      return;
    }
    if (!current.hasMore || current.isLoadingMore || current.commits.isEmpty) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.log(
        path: current.path,
        limit: _limit,
        from: current.commits.last.oid,
      );
      emit(
        HistoryReady(
          [...current.commits, ...next],
          path: current.path,
          hasMore: next.length == _limit,
        ),
      );
    } on GitFailure catch (failure) {
      emit(HistoryError(failure));
    }
  }
}
