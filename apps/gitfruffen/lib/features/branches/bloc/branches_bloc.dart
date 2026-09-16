import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'branches_event.dart';
import 'branches_state.dart';

/// Loads local and remote branches and performs checkouts.
class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
  BranchesBloc({required GitRepositoryContract repository})
    : _repository = repository,
      super(const BranchesInitial()) {
    on<BranchesLoaded>(_onLoaded);
    on<BranchCheckedOut>(_onCheckedOut);
  }

  final GitRepositoryContract _repository;

  Future<void> _onLoaded(
    BranchesLoaded event,
    Emitter<BranchesState> emit,
  ) async {
    emit(const BranchesLoading());
    try {
      final branches = await _repository.branches(path: event.path);
      emit(BranchesReady(branches));
    } on GitFailure catch (failure) {
      emit(BranchesError(failure));
    }
  }

  Future<void> _onCheckedOut(
    BranchCheckedOut event,
    Emitter<BranchesState> emit,
  ) async {
    emit(const BranchesLoading());
    try {
      await _repository.checkout(path: event.path, branchName: event.branch);
      final branches = await _repository.branches(path: event.path);
      emit(BranchesReady(branches));
    } on GitFailure catch (failure) {
      emit(BranchesError(failure));
    }
  }
}
