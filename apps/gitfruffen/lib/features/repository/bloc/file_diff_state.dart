import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:git_core/git_core.dart';

/// Where the open file diff comes from.
enum FileDiffSource { commit, staged, unstaged }

/// Request to open [file] in the diff view for [repositoryPath].
@immutable
class OpenFileRequest extends Equatable {
  const OpenFileRequest({
    required this.repositoryPath,
    required this.file,
    required this.source,
    this.commitOid,
  });

  final String repositoryPath;
  final DiffFile file;
  final FileDiffSource source;
  final GitOid? commitOid;

  @override
  List<Object?> get props => [repositoryPath, file, source, commitOid];
}

/// State exposed by `FileDiffBloc`.
@immutable
class FileDiffState extends Equatable {
  const FileDiffState({
    required this.repositoryPath,
    required this.source,
    required this.file,
    this.commitOid,
    this.ignoreWhitespace = false,
    this.fullFile = false,
    this.blame = const [],
    this.isLoadingBlame = false,
    this.history = const [],
    this.isLoadingHistory = false,
    this.isLoadingDiff = false,
    this.failure,
  });

  final String repositoryPath;
  final FileDiffSource source;
  final DiffFile file;
  final GitOid? commitOid;

  /// Whether whitespace-only changes are hidden from [file].
  final bool ignoreWhitespace;

  /// Whether [file] was diffed with enough context to show the whole file.
  final bool fullFile;

  /// Blame entries for [file], empty until requested.
  final List<BlameLine> blame;

  /// Whether [blame] is being loaded.
  final bool isLoadingBlame;

  /// Commits that changed [file], empty until requested.
  final List<Commit> history;

  /// Whether [history] is being loaded.
  final bool isLoadingHistory;

  /// Whether [file] is being re-diffed.
  final bool isLoadingDiff;

  /// Failure from the last operation, or `null` when it succeeded.
  final GitFailure? failure;

  FileDiffState copyWith({
    String? repositoryPath,
    FileDiffSource? source,
    DiffFile? file,
    GitOid? commitOid,
    bool? ignoreWhitespace,
    bool? fullFile,
    List<BlameLine>? blame,
    bool? isLoadingBlame,
    List<Commit>? history,
    bool? isLoadingHistory,
    bool? isLoadingDiff,
    GitFailure? failure,
    bool clearFailure = false,
    bool clearBlame = false,
  }) => FileDiffState(
    repositoryPath: repositoryPath ?? this.repositoryPath,
    source: source ?? this.source,
    file: file ?? this.file,
    commitOid: commitOid ?? this.commitOid,
    ignoreWhitespace: ignoreWhitespace ?? this.ignoreWhitespace,
    fullFile: fullFile ?? this.fullFile,
    blame: clearBlame ? const [] : (blame ?? this.blame),
    isLoadingBlame: isLoadingBlame ?? this.isLoadingBlame,
    history: history ?? this.history,
    isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    isLoadingDiff: isLoadingDiff ?? this.isLoadingDiff,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [
    repositoryPath,
    source,
    file,
    commitOid,
    ignoreWhitespace,
    fullFile,
    blame,
    isLoadingBlame,
    history,
    isLoadingHistory,
    isLoadingDiff,
    failure,
  ];
}
