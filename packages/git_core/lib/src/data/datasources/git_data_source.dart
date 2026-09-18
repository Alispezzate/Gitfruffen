import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/git_reset_mode.dart';
import 'package:git_core/src/domain/entities/reflog.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/entities/stash.dart';
import 'package:git_core/src/domain/entities/worktree.dart';

/// Low-level contract over the native Git engine (libgit2).
///
/// This is the only place allowed to speak the engine's vocabulary. The
/// presentation layer must never reach this type.
abstract interface class GitDataSource {
  Future<GitRepository> open({required String path});

  Future<GitRepository> discover({required String startPath});

  Future<GitRepository> clone({required String url, required String localPath});

  Future<GitRepository> init({required String path, bool bare = false});

  Future<RepositoryStatus> status({required String path});

  /// Returns the commit log reachable from HEAD, newest first.
  ///
  /// [from] is an exclusive cursor: when set, the walk starts after that
  /// commit, so callers can request successive pages without duplicates.
  Future<List<Commit>> log({required String path, int limit, GitOid? from});

  /// Returns commits reachable from all local branches, newest first.
  ///
  /// Unlike [log], this includes every branch head, which is what the commit
  /// graph needs to draw intersecting lines.
  Future<List<Commit>> graph({required String path, int limit, GitOid? from});

  Future<List<Branch>> branches({required String path});

  Future<List<Tag>> tags({required String path});

  Future<List<Remote>> remotes({required String path});

  Future<List<WorktreeInfo>> worktrees({required String path});

  Future<List<StashEntry>> stashes({required String path});

  /// Returns the reflog of the current branch, newest first.
  Future<List<ReflogEntry>> reflog({required String path});

  Future<void> stage({required String path, required List<String> paths});

  Future<void> unstage({required String path, required List<String> paths});

  Future<Commit> commit({
    required String path,
    required String message,
    bool amend,
  });

  Future<void> checkout({required String path, required String branchName});

  Future<Branch> createBranch({
    required String path,
    required String name,
    String? targetOid,
    bool checkout,
  });

  Future<void> deleteBranch({required String path, required String name});

  Future<void> stash({required String path, String? message});

  Future<void> applyStash({required String path, required int index});

  Future<void> popStash({required String path, required int index});

  Future<void> dropStash({required String path, required int index});

  Future<WorktreeInfo> addWorktree({
    required String path,
    required String name,
    required String worktreePath,
    String? ref,
  });

  Future<void> removeWorktree({
    required String path,
    required String name,
    bool force,
  });

  Future<void> pruneWorktrees({required String path});

  Future<void> fetch({required String path, String remoteName});

  Future<void> pull({required String path, String remoteName});

  Future<void> push({
    required String path,
    String remoteName,
    String? branchName,
  });

  /// Resets the current branch to [oid].
  Future<void> resetTo({
    required String path,
    required String oid,
    GitResetMode mode,
  });

  Future<void> dispose({required String path});
}
