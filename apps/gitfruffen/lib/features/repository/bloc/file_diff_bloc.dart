import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import 'package:gitfruffen/features/repository/bloc/file_diff_event.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';

/// Owns the file opened in the diff view: its current diff, blame, history and
/// the source (commit, staged or unstaged) it was opened from.
///
/// Depends only on `GitRepositoryContract`, keeping it independent from
/// libgit2 and trivially testable.
class FileDiffBloc extends Bloc<FileDiffEvent, FileDiffState> {
  FileDiffBloc({
    required GitRepositoryContract repository,
    required OpenFileRequest request,
  }) : _repository = repository,
       super(
         FileDiffState(
           repositoryPath: request.repositoryPath,
           source: request.source,
           file: request.file,
           commitOid: request.commitOid,
         ),
       ) {
    on<FileDiffWhitespaceToggled>(_onWhitespaceToggled);
    on<FileDiffFullFileToggled>(_onFullFileToggled);
    on<FileDiffBlameRequested>(_onBlameRequested);
    on<FileDiffHistoryRequested>(_onHistoryRequested);
    on<FileDiffHistoryCommitSelected>(_onHistoryCommitSelected);
  }

  final GitRepositoryContract _repository;

  // ponytail: context is capped at this many lines; files larger than that are
  // not shown in full.
  static const int _fullFileContextLines = 1 << 20;

  int _contextLines(bool fullFile) => fullFile ? _fullFileContextLines : 3;

  Future<void> _onWhitespaceToggled(
    FileDiffWhitespaceToggled event,
    Emitter<FileDiffState> emit,
  ) async {
    emit(
      state.copyWith(
        ignoreWhitespace: event.ignoreWhitespace,
        isLoadingDiff: true,
        clearFailure: true,
      ),
    );
    try {
      final result = await _diff(state, event.ignoreWhitespace, state.fullFile);
      emit(
        state.copyWith(
          file: _findFile(result, state.file),
          isLoadingDiff: false,
        ),
      );
    } on GitFailure catch (failure) {
      emit(state.copyWith(isLoadingDiff: false, failure: failure));
    }
  }

  Future<void> _onFullFileToggled(
    FileDiffFullFileToggled event,
    Emitter<FileDiffState> emit,
  ) async {
    if (state.fullFile == event.fullFile) {
      return;
    }
    emit(
      state.copyWith(
        fullFile: event.fullFile,
        isLoadingDiff: true,
        clearFailure: true,
      ),
    );
    try {
      final result = await _diff(state, state.ignoreWhitespace, event.fullFile);
      emit(
        state.copyWith(
          file: _findFile(result, state.file),
          isLoadingDiff: false,
        ),
      );
    } on GitFailure catch (failure) {
      emit(state.copyWith(isLoadingDiff: false, failure: failure));
    }
  }

  Future<void> _onBlameRequested(
    FileDiffBlameRequested event,
    Emitter<FileDiffState> emit,
  ) async {
    if (state.isLoadingBlame) {
      return;
    }
    emit(state.copyWith(isLoadingBlame: true, clearFailure: true));
    try {
      final lines = await _repository.blameFile(
        path: state.repositoryPath,
        filePath: state.file.path,
        at: state.source == FileDiffSource.commit ? state.commitOid : null,
      );
      emit(state.copyWith(blame: lines, isLoadingBlame: false));
    } on GitFailure catch (failure) {
      emit(state.copyWith(isLoadingBlame: false, failure: failure));
    }
  }

  Future<void> _onHistoryRequested(
    FileDiffHistoryRequested event,
    Emitter<FileDiffState> emit,
  ) async {
    if (state.isLoadingHistory || state.history.isNotEmpty) {
      return;
    }
    emit(state.copyWith(isLoadingHistory: true, clearFailure: true));
    try {
      final commits = await _repository.fileHistory(
        path: state.repositoryPath,
        filePath: state.file.path,
      );
      emit(state.copyWith(history: commits, isLoadingHistory: false));
    } on GitFailure catch (failure) {
      emit(state.copyWith(isLoadingHistory: false, failure: failure));
    }
  }

  Future<void> _onHistoryCommitSelected(
    FileDiffHistoryCommitSelected event,
    Emitter<FileDiffState> emit,
  ) async {
    emit(state.copyWith(isLoadingDiff: true, clearFailure: true));
    try {
      final result = await _repository.diffCommit(
        path: state.repositoryPath,
        oid: event.oid,
        ignoreWhitespace: state.ignoreWhitespace,
        contextLines: _contextLines(state.fullFile),
      );
      emit(
        state.copyWith(
          file: _findFile(result, state.file),
          source: FileDiffSource.commit,
          commitOid: event.oid,
          isLoadingDiff: false,
          clearBlame: true,
        ),
      );
    } on GitFailure catch (failure) {
      emit(state.copyWith(isLoadingDiff: false, failure: failure));
    }
  }

  Future<DiffResult> _diff(
    FileDiffState state,
    bool ignoreWhitespace,
    bool fullFile,
  ) => switch (state.source) {
    FileDiffSource.commit => _repository.diffCommit(
      path: state.repositoryPath,
      oid: state.commitOid!,
      ignoreWhitespace: ignoreWhitespace,
      contextLines: _contextLines(fullFile),
    ),
    FileDiffSource.staged => _repository.diffWorkingTree(
      path: state.repositoryPath,
      staged: true,
      ignoreWhitespace: ignoreWhitespace,
      contextLines: _contextLines(fullFile),
    ),
    FileDiffSource.unstaged => _repository.diffWorkingTree(
      path: state.repositoryPath,
      staged: false,
      ignoreWhitespace: ignoreWhitespace,
      contextLines: _contextLines(fullFile),
    ),
  };

  /// Returns the diff of [current] in [result], or an empty diff when the file
  /// no longer appears (e.g. its change was reverted).
  DiffFile _findFile(DiffResult result, DiffFile current) {
    for (final file in result.files) {
      if (_matches(file, current)) {
        return file;
      }
    }
    return _emptyFile(current);
  }

  bool _matches(DiffFile file, DiffFile current) =>
      file.path == current.path ||
      file.path == current.oldPath ||
      file.oldPath == current.path ||
      (current.oldPath != null && file.oldPath == current.oldPath);

  DiffFile _emptyFile(DiffFile file) => DiffFile(
    path: file.path,
    oldPath: file.oldPath,
    changeType: file.changeType,
    isBinary: file.isBinary,
    insertions: 0,
    deletions: 0,
  );
}
