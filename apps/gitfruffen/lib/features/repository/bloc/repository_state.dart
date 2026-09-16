import 'package:equatable/equatable.dart';
import 'package:git_core/git_core.dart';

/// State exposed by `RepositoryBloc`.
sealed class RepositoryState extends Equatable {
  const RepositoryState();

  @override
  List<Object?> get props => [];
}

/// No repository is open yet.
final class RepositoryInitial extends RepositoryState {
  const RepositoryInitial();
}

/// An open/clone operation is in progress.
final class RepositoryLoading extends RepositoryState {
  const RepositoryLoading();
}

/// A repository is open and its status has been loaded.
final class RepositoryReady extends RepositoryState {
  const RepositoryReady({required this.repository, required this.status});

  final GitRepository repository;
  final RepositoryStatus status;

  @override
  List<Object?> get props => [repository, status];
}

/// The last operation failed.
final class RepositoryError extends RepositoryState {
  const RepositoryError(this.failure);

  final GitFailure failure;

  @override
  List<Object?> get props => [failure];
}
