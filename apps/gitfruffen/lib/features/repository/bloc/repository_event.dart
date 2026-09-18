import 'package:equatable/equatable.dart';

/// Events accepted by `RepositoryBloc`.
sealed class RepositoryEvent extends Equatable {
  const RepositoryEvent();

  @override
  List<Object?> get props => [];
}

/// Opens (or re-opens) the repository at [path] in a new tab.
final class RepositoryOpened extends RepositoryEvent {
  const RepositoryOpened(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

/// Clones [url] into [localPath] and opens the result in a new tab.
final class RepositoryCloned extends RepositoryEvent {
  const RepositoryCloned({required this.url, required this.localPath});

  final String url;
  final String localPath;

  @override
  List<Object?> get props => [url, localPath];
}

/// Activates an already open tab, identified by the repository [path].
final class RepositoryTabSelected extends RepositoryEvent {
  const RepositoryTabSelected(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

/// Closes the tab identified by [path]. Closing the active tab activates its
/// neighbour; closing the last tab returns to the initial state.
final class RepositoryTabClosed extends RepositoryEvent {
  const RepositoryTabClosed(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

/// Refreshes the workspace snapshot of the repository identified by [path],
/// defaulting to the active tab.
final class RepositoryRefreshed extends RepositoryEvent {
  const RepositoryRefreshed([this.path]);

  final String? path;

  @override
  List<Object?> get props => [path];
}

/// Appends the next page of the commit graph for the active tab.
final class RepositoryGraphLoadMore extends RepositoryEvent {
  const RepositoryGraphLoadMore();
}

/// Closes the currently active repository.
final class RepositoryClosed extends RepositoryEvent {
  const RepositoryClosed();
}

/// Stages [paths] in the active repository.
final class FilesStaged extends RepositoryEvent {
  const FilesStaged(this.paths);

  final List<String> paths;

  @override
  List<Object?> get props => [paths];
}

/// Unstages [paths] in the active repository.
final class FilesUnstaged extends RepositoryEvent {
  const FilesUnstaged(this.paths);

  final List<String> paths;

  @override
  List<Object?> get props => [paths];
}

/// Stages every change of the active repository.
final class AllFilesStaged extends RepositoryEvent {
  const AllFilesStaged();
}

/// Unstages every change of the active repository.
final class AllFilesUnstaged extends RepositoryEvent {
  const AllFilesUnstaged();
}

/// Creates a commit with [message] from the current index.
final class CommitSubmitted extends RepositoryEvent {
  const CommitSubmitted(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Checks out [branch] in the active repository.
final class BranchCheckedOut extends RepositoryEvent {
  const BranchCheckedOut(this.branch);

  final String branch;

  @override
  List<Object?> get props => [branch];
}

/// Creates a branch named [name], optionally checking it out.
final class BranchCreated extends RepositoryEvent {
  const BranchCreated({required this.name, this.checkout = false});

  final String name;
  final bool checkout;

  @override
  List<Object?> get props => [name, checkout];
}

/// Deletes the branch named [name].
final class BranchDeleted extends RepositoryEvent {
  const BranchDeleted(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

/// Stashes the current working tree changes with an optional [message].
final class StashCreated extends RepositoryEvent {
  const StashCreated([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Applies the stash at [index], keeping it in the list.
final class StashApplied extends RepositoryEvent {
  const StashApplied(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Applies and removes the stash at [index].
final class StashPopped extends RepositoryEvent {
  const StashPopped(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Removes the stash at [index].
final class StashDropped extends RepositoryEvent {
  const StashDropped(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Adds a linked worktree named [name] at [path].
final class WorktreeCreated extends RepositoryEvent {
  const WorktreeCreated({required this.name, required this.path, this.ref});

  final String name;
  final String path;
  final String? ref;

  @override
  List<Object?> get props => [name, path, ref];
}

/// Removes the linked worktree named [name].
final class WorktreeRemoved extends RepositoryEvent {
  const WorktreeRemoved(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

/// Pushes the current branch to the default remote.
final class RepositoryPushed extends RepositoryEvent {
  const RepositoryPushed();
}

/// Pulls the default remote into the current branch.
final class RepositoryPulled extends RepositoryEvent {
  const RepositoryPulled();
}

/// Moves HEAD back to the previous reflog position.
final class UndoRequested extends RepositoryEvent {
  const UndoRequested();
}

/// Re-applies the last undone HEAD position.
final class RedoRequested extends RepositoryEvent {
  const RedoRequested();
}
