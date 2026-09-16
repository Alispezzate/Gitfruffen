import 'package:equatable/equatable.dart';

/// Events accepted by `RepositoryBloc`.
sealed class RepositoryEvent extends Equatable {
  const RepositoryEvent();

  @override
  List<Object?> get props => [];
}

/// Opens (or re-opens) the repository at [path].
final class RepositoryOpened extends RepositoryEvent {
  const RepositoryOpened(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

/// Clones [url] into [localPath] and opens the result.
final class RepositoryCloned extends RepositoryEvent {
  const RepositoryCloned({required this.url, required this.localPath});

  final String url;
  final String localPath;

  @override
  List<Object?> get props => [url, localPath];
}

/// Refreshes the status of the currently open repository.
final class RepositoryRefreshed extends RepositoryEvent {
  const RepositoryRefreshed();
}

/// Closes the currently open repository.
final class RepositoryClosed extends RepositoryEvent {
  const RepositoryClosed();
}
