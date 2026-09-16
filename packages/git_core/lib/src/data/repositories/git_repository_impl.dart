import 'package:git_core/src/data/datasources/git_data_source.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/repositories/git_repository.dart';

/// Default [GitRepositoryContract] implementation.
///
/// It is a thin orchestration layer: it forwards to [GitDataSource] and maps
/// engine errors into typed domain failures. All mapping concerns live in the
/// data source and mappers, keeping this class free of native bindings.
final class GitRepositoryImpl implements GitRepositoryContract {
  const GitRepositoryImpl({required GitDataSource dataSource})
    : _dataSource = dataSource;

  final GitDataSource _dataSource;

  @override
  Future<GitRepository> open({required String path}) =>
      _dataSource.open(path: path);

  @override
  Future<GitRepository> discover({required String startPath}) =>
      _dataSource.discover(startPath: startPath);

  @override
  Future<GitRepository> clone({
    required String url,
    required String localPath,
  }) => _dataSource.clone(url: url, localPath: localPath);

  @override
  Future<GitRepository> init({required String path, bool bare = false}) =>
      _dataSource.init(path: path, bare: bare);

  @override
  Future<RepositoryStatus> status({required String path}) =>
      _dataSource.status(path: path);

  @override
  Future<List<Commit>> log({
    required String path,
    int limit = 100,
    GitOid? from,
  }) => _dataSource.log(path: path, limit: limit, from: from);

  @override
  Future<List<Branch>> branches({required String path}) =>
      _dataSource.branches(path: path);

  @override
  Future<List<Tag>> tags({required String path}) =>
      _dataSource.tags(path: path);

  @override
  Future<List<Remote>> remotes({required String path}) =>
      _dataSource.remotes(path: path);

  @override
  Future<void> stage({required String path, required List<String> paths}) =>
      _dataSource.stage(path: path, paths: paths);

  @override
  Future<void> unstage({required String path, required List<String> paths}) =>
      _dataSource.unstage(path: path, paths: paths);

  @override
  Future<Commit> commit({
    required String path,
    required String message,
    bool amend = false,
  }) => _dataSource.commit(path: path, message: message, amend: amend);

  @override
  Future<void> checkout({required String path, required String branchName}) =>
      _dataSource.checkout(path: path, branchName: branchName);

  @override
  Future<void> fetch({required String path, String remoteName = 'origin'}) =>
      _dataSource.fetch(path: path, remoteName: remoteName);

  @override
  Future<void> push({
    required String path,
    String remoteName = 'origin',
    String? branchName,
  }) => _dataSource.push(
    path: path,
    remoteName: remoteName,
    branchName: branchName,
  );

  @override
  Future<void> dispose({required String path}) =>
      _dataSource.dispose(path: path);
}
