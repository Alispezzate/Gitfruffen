part of 'dependency_injector.dart';

/// Layer 2 - providers (services and datasources).
///
/// The only implementation choice we make here is the [GitDataSource]: swap
/// [Libgit2GitDataSource] for [FakeGitDataSource] to run the UI without the
/// native engine.
List<SingleChildWidget> _providers(SharedPreferences preferences) => [
  Provider<SharedPreferences>.value(value: preferences),
  Provider<GitDataSource>(create: (_) => Libgit2GitDataSource()),
  Provider<FilePickerService>(create: (_) => const NativeFilePickerService()),
];
