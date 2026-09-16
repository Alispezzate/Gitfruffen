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
  const HistoryReady(this.commits);

  final List<Commit> commits;

  @override
  List<Object?> get props => [commits];
}

final class HistoryError extends HistoryState {
  const HistoryError(this.failure);

  final GitFailure failure;

  @override
  List<Object?> get props => [failure];
}
