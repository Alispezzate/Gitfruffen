import 'package:equatable/equatable.dart';
import 'package:git_core/git_core.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

final class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryReady extends HistoryState {
  const HistoryReady(
    this.commits, {
    required this.path,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<Commit> commits;

  /// Repository the loaded [commits] belong to, used as cursor source.
  final String path;

  /// Whether the repository may contain older commits beyond [commits].
  final bool hasMore;

  /// Whether a follow-up page is currently being fetched.
  final bool isLoadingMore;

  HistoryReady copyWith({
    List<Commit>? commits,
    bool? hasMore,
    bool? isLoadingMore,
  }) => HistoryReady(
    commits ?? this.commits,
    path: path,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [commits, path, hasMore, isLoadingMore];
}

final class HistoryError extends HistoryState {
  const HistoryError(this.failure);

  final GitFailure failure;

  @override
  List<Object?> get props => [failure];
}
