part of 'dependency_injector.dart';

/// Layer 3 - repositories.
///
/// Abstractions consumed by the blocs. The blocs depend on the interfaces
/// declared in `git_core`, never on their concrete implementations.
List<RepositoryProvider> _repositories() => [
  RepositoryProvider<GitRepositoryContract>(
    create: (context) =>
        GitRepositoryImpl(dataSource: context.read<GitDataSource>()),
  ),
  RepositoryProvider<WorkspaceRepositoryContract>(
    create: (context) => WorkspaceRepositoryImpl(preferences: context.read()),
  ),
];
