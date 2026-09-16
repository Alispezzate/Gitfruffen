import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Base failure type for every Git operation.
///
/// Implementations are `sealed` so callers get exhaustive `switch` support.
@immutable
sealed class GitFailure extends Equatable {
  const GitFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}

/// The repository path is invalid or no repository was found.
final class RepositoryNotFoundFailure extends GitFailure {
  const RepositoryNotFoundFailure(super.message, {super.cause});
}

/// Authentication against a remote failed.
final class AuthenticationFailure extends GitFailure {
  const AuthenticationFailure(super.message, {super.cause});
}

/// The network operation (fetch/push/clone) failed.
final class NetworkFailure extends GitFailure {
  const NetworkFailure(super.message, {super.cause});
}

/// A merge/rebase produced conflicts that need user resolution.
final class ConflictFailure extends GitFailure {
  const ConflictFailure(super.message, {super.cause});
}

/// The working tree is dirty and the operation requires a clean state.
final class DirtyWorkingTreeFailure extends GitFailure {
  const DirtyWorkingTreeFailure(super.message, {super.cause});
}

/// Anything not covered above.
final class UnexpectedGitFailure extends GitFailure {
  const UnexpectedGitFailure(super.message, {super.cause});
}
