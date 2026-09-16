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

/// Refreshes the status of the repository identified by [path], defaulting to
/// the active tab.
final class RepositoryRefreshed extends RepositoryEvent {
  const RepositoryRefreshed([this.path]);

  final String? path;

  @override
  List<Object?> get props => [path];
}

/// Closes the currently active repository.
final class RepositoryClosed extends RepositoryEvent {
  const RepositoryClosed();
}
