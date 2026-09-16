import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'history_event.dart';
import 'history_state.dart';

/// Loads the commit log of the currently open repository.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required GitRepositoryContract repository})
    : _repository = repository,
      super(const HistoryInitial()) {
    on<HistoryLoaded>(_onLoaded);
  }

  final GitRepositoryContract _repository;

  Future<void> _onLoaded(
    HistoryLoaded event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    try {
      final commits = await _repository.log(
        path: event.path,
        limit: event.limit,
      );
      emit(HistoryReady(commits));
    } on GitFailure catch (failure) {
      emit(HistoryError(failure));
    }
  }
}
