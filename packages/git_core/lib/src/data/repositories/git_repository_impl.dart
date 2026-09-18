import 'package:git_core/src/data/datasources/git_data_source.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/git_reset_mode.dart';
import 'package:git_core/src/domain/entities/reflog.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/entities/stash.dart';
import 'package:git_core/src/domain/entities/worktree.dart';
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
  Future<List<Commit>> graph({
    required String path,
    int limit = 100,
    GitOid? from,
  }) => _dataSource.graph(path: path, limit: limit, from: from);

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
  Future<List<WorktreeInfo>> worktrees({required String path}) =>
      _dataSource.worktrees(path: path);

  @override
  Future<List<StashEntry>> stashes({required String path}) =>
      _dataSource.stashes(path: path);

  @override
  Future<List<ReflogEntry>> reflog({required String path}) =>
      _dataSource.reflog(path: path);

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
  Future<Branch> createBranch({
    required String path,
    required String name,
    String? targetOid,
    bool checkout = false,
  }) => _dataSource.createBranch(
    path: path,
    name: name,
    targetOid: targetOid,
    checkout: checkout,
  );

  @override
  Future<void> deleteBranch({required String path, required String name}) =>
      _dataSource.deleteBranch(path: path, name: name);

  @override
  Future<void> stash({required String path, String? message}) =>
      _dataSource.stash(path: path, message: message);

  @override
  Future<void> applyStash({required String path, required int index}) =>
      _dataSource.applyStash(path: path, index: index);

  @override
  Future<void> popStash({required String path, required int index}) =>
      _dataSource.popStash(path: path, index: index);

  @override
  Future<void> dropStash({required String path, required int index}) =>
      _dataSource.dropStash(path: path, index: index);

  @override
  Future<WorktreeInfo> addWorktree({
    required String path,
    required String name,
    required String worktreePath,
    String? ref,
  }) => _dataSource.addWorktree(
    path: path,
    name: name,
    worktreePath: worktreePath,
    ref: ref,
  );

  @override
  Future<void> removeWorktree({
    required String path,
    required String name,
    bool force = false,
  }) => _dataSource.removeWorktree(path: path, name: name, force: force);

  @override
  Future<void> pruneWorktrees({required String path}) =>
      _dataSource.pruneWorktrees(path: path);

  @override
  Future<void> fetch({required String path, String remoteName = 'origin'}) =>
      _dataSource.fetch(path: path, remoteName: remoteName);

  @override
  Future<void> pull({required String path, String remoteName = 'origin'}) =>
      _dataSource.pull(path: path, remoteName: remoteName);

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
  Future<void> resetTo({
    required String path,
    required String oid,
    GitResetMode mode = GitResetMode.hard,
  }) => _dataSource.resetTo(path: path, oid: oid, mode: mode);

  @override
  Future<void> dispose({required String path}) =>
      _dataSource.dispose(path: path);
}
