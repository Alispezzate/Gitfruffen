part of 'dependency_injector.dart';

/// Layer 1 - mappers.
///
/// Translate engine objects (`git2dart`) into immutable domain entities so the
/// presentation layer never depends on libgit2 types.
List<SingleChildWidget> _mappers() => [
  Provider<GitObjectMapper>(create: (_) => const GitObjectMapper()),
];
