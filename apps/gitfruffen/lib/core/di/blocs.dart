part of 'dependency_injector.dart';

/// Layer 4 - blocs (application logic and state).
///
/// Global-scoped blocs are created here. Feature-scoped blocs can also be
/// created per-route via `BlocProvider` when their lifetime is shorter.
List<BlocProvider> _blocs() => [
  BlocProvider<SettingsBloc>(
    create: (context) => SettingsBloc(
      workspace: context.read<WorkspaceRepositoryContract>(),
      dataSource: context.read<GitDataSource>(),
    )..add(const SettingsLoaded()),
  ),
  BlocProvider<RepositoryBloc>(
    create: (context) => RepositoryBloc(
      repository: context.read<GitRepositoryContract>(),
      workspace: context.read<WorkspaceRepositoryContract>(),
    ),
  ),
];
