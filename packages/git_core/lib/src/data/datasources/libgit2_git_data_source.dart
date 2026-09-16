import 'package:git2dart/git2dart.dart' as libgit2;
import 'package:git_core/src/data/datasources/git_data_source.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/failures/git_failure.dart';

/// [GitDataSource] backed by libgit2 through the `git2dart` FFI bindings.
///
/// This is the only class in the codebase that may touch native Git resources.
/// Native handles are opened per operation and always released before the
/// future completes.
///
/// NOTE: implementation lands in the next milestone. Until then every method
/// fails fast with an [UnexpectedGitFailure] so the wiring can be exercised
/// end-to-end without native side effects.
final class Libgit2GitDataSource implements GitDataSource {
  Libgit2GitDataSource();

  /// Version of the bundled libgit2, useful for diagnostics in the Settings UI.
  String get engineVersion => libgit2.Libgit2.version;

  Never _notImplemented(String operation) {
    throw UnexpectedGitFailure(
      'Libgit2GitDataSource.$operation is not implemented yet.',
    );
  }

  @override
  Future<GitRepository> open({required String path}) async =>
      _notImplemented('open');

  @override
  Future<GitRepository> discover({required String startPath}) async =>
      _notImplemented('discover');

  @override
  Future<GitRepository> clone({
    required String url,
    required String localPath,
  }) async => _notImplemented('clone');

  @override
  Future<GitRepository> init({required String path, bool bare = false}) async =>
      _notImplemented('init');

  @override
  Future<RepositoryStatus> status({required String path}) async =>
      _notImplemented('status');

  @override
  Future<List<Commit>> log({
    required String path,
    int limit = 100,
    GitOid? from,
  }) async => _notImplemented('log');

  @override
  Future<List<Branch>> branches({required String path}) async =>
      _notImplemented('branches');

  @override
  Future<List<Tag>> tags({required String path}) async =>
      _notImplemented('tags');

  @override
  Future<List<Remote>> remotes({required String path}) async =>
      _notImplemented('remotes');

  @override
  Future<void> stage({
    required String path,
    required List<String> paths,
  }) async => _notImplemented('stage');

  @override
  Future<void> unstage({
    required String path,
    required List<String> paths,
  }) async => _notImplemented('unstage');

  @override
  Future<Commit> commit({
    required String path,
    required String message,
    bool amend = false,
  }) async => _notImplemented('commit');

  @override
  Future<void> checkout({
    required String path,
    required String branchName,
  }) async => _notImplemented('checkout');

  @override
  Future<void> fetch({
    required String path,
    String remoteName = 'origin',
  }) async => _notImplemented('fetch');

  @override
  Future<void> push({
    required String path,
    String remoteName = 'origin',
    String? branchName,
  }) async => _notImplemented('push');

  @override
  Future<void> dispose({required String path}) async {}
}
