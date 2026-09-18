import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/remote.dart';

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

  /// Returns all local and remote branches.
  Future<List<Branch>> branches({required String path});

  /// Returns all tags.
  Future<List<Tag>> tags({required String path});

  /// Returns the configured remotes.
  Future<List<Remote>> remotes({required String path});

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

  /// Fetches from [remoteName] (defaults to `origin`).
  Future<void> fetch({required String path, String remoteName = 'origin'});

  /// Pushes [branchName] to [remoteName].
  Future<void> push({
    required String path,
    String remoteName = 'origin',
    String? branchName,
  });

  /// Releases any native resources associated with [path].
  Future<void> dispose({required String path});
}
