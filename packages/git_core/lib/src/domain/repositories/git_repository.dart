import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/git_reset_mode.dart';
import 'package:git_core/src/domain/entities/reflog.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/entities/stash.dart';
import 'package:git_core/src/domain/entities/worktree.dart';

/// Contract for every Git operation exposed to the application layer.
///
/// The presentation layer never depends on libgit2 directly: it consumes this
/// abstraction through the Pine `repositories` layer.
abstract interface class GitRepositoryContract {
  /// Opens an existing repository rooted at [path].
  Future<GitRepository> open({required String path});

  /// Discovers the repository containing [startPath].
  Future<GitRepository> discover({required String startPath});

  /// Clones [url] into [localPath].
  Future<GitRepository> clone({required String url, required String localPath});

  /// Initialises a new repository at [path].
  Future<GitRepository> init({required String path, bool bare = false});

  /// Returns the current working tree status.
  Future<RepositoryStatus> status({required String path});

  /// Returns the commit log reachable from HEAD, newest first.
  ///
  /// When [from] is provided it is treated as an exclusive cursor: the log
  /// starts after that commit, which makes paginated loading possible by
  /// passing the last commit of the previous page.
  Future<List<Commit>> log({
    required String path,
    int limit = 100,
    GitOid? from,
  });

  /// Returns commits reachable from all local branches, newest first.
  Future<List<Commit>> graph({
    required String path,
    int limit = 100,
    GitOid? from,
  });

  /// Returns all local and remote branches.
  Future<List<Branch>> branches({required String path});

  /// Returns all tags.
  Future<List<Tag>> tags({required String path});

  /// Returns the configured remotes.
  Future<List<Remote>> remotes({required String path});

  /// Returns the linked working trees of the repository.
  Future<List<WorktreeInfo>> worktrees({required String path});

  /// Returns the stash entries, most recent first.
  Future<List<StashEntry>> stashes({required String path});

  /// Returns the reflog of the current branch, newest first.
  Future<List<ReflogEntry>> reflog({required String path});

  /// Stages [paths] in the index.
  Future<void> stage({required String path, required List<String> paths});

  /// Unstages [paths] from the index.
  Future<void> unstage({required String path, required List<String> paths});

  /// Creates a commit from the current index.
  Future<Commit> commit({
    required String path,
    required String message,
    bool amend = false,
  });

  /// Checks out the branch named [branchName].
  Future<void> checkout({required String path, required String branchName});

  /// Creates a branch named [name].
  ///
  /// When [targetOid] is omitted the branch points at HEAD. When [checkout]
  /// is true the new branch is also checked out.
  Future<Branch> createBranch({
    required String path,
    required String name,
    String? targetOid,
    bool checkout = false,
  });

  /// Deletes the branch named [name].
  Future<void> deleteBranch({required String path, required String name});

  /// Stashes the current working tree changes.
  Future<void> stash({required String path, String? message});

  /// Applies the stash at [index] without removing it.
  Future<void> applyStash({required String path, required int index});

  /// Applies and removes the stash at [index].
  Future<void> popStash({required String path, required int index});

  /// Removes the stash at [index] without applying it.
  Future<void> dropStash({required String path, required int index});

  /// Adds a linked worktree named [name] at [worktreePath].
  Future<WorktreeInfo> addWorktree({
    required String path,
    required String name,
    required String worktreePath,
    String? ref,
  });

  /// Removes the linked worktree named [name].
  Future<void> removeWorktree({
    required String path,
    required String name,
    bool force = false,
  });

  /// Prunes worktree administrative data for missing worktrees.
  Future<void> pruneWorktrees({required String path});

  /// Fetches from [remoteName] (defaults to `origin`).
  Future<void> fetch({required String path, String remoteName = 'origin'});

  /// Fetches [remoteName] and integrates it into the current branch.
  Future<void> pull({required String path, String remoteName = 'origin'});

  /// Pushes [branchName] to [remoteName].
  Future<void> push({
    required String path,
    String remoteName = 'origin',
    String? branchName,
  });

  /// Resets the current branch to [oid], optionally discarding changes.
  Future<void> resetTo({
    required String path,
    required String oid,
    GitResetMode mode = GitResetMode.hard,
  });

  /// Releases any native resources associated with [path].
  Future<void> dispose({required String path});
}
