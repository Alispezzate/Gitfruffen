import 'package:equatable/equatable.dart';
import 'package:git_core/git_core.dart';

/// Events accepted by `FileDiffBloc`.
sealed class FileDiffEvent extends Equatable {
  const FileDiffEvent();

  @override
  List<Object?> get props => [];
}

/// Re-diffs the current file with whitespace-only changes hidden or shown.
final class FileDiffWhitespaceToggled extends FileDiffEvent {
  // ignore: avoid_positional_boolean_parameters
  const FileDiffWhitespaceToggled(this.ignoreWhitespace);

  final bool ignoreWhitespace;

  @override
  List<Object?> get props => [ignoreWhitespace];
}

/// Re-diffs the current file with enough context to show it entirely.
final class FileDiffFullFileToggled extends FileDiffEvent {
  // ignore: avoid_positional_boolean_parameters
  const FileDiffFullFileToggled(this.fullFile);

  final bool fullFile;

  @override
  List<Object?> get props => [fullFile];
}

/// Loads the blame entries of the current file.
final class FileDiffBlameRequested extends FileDiffEvent {
  const FileDiffBlameRequested();
}

/// Loads the commits that changed the current file.
final class FileDiffHistoryRequested extends FileDiffEvent {
  const FileDiffHistoryRequested();
}

/// Shows the version of the current file introduced by [oid].
final class FileDiffHistoryCommitSelected extends FileDiffEvent {
  const FileDiffHistoryCommitSelected(this.oid);

  final GitOid oid;

  @override
  List<Object?> get props => [oid];
}
