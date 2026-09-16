import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/remote.dart';

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

  Future<List<Commit>> log({required String path, int limit, GitOid? from});

  Future<List<Branch>> branches({required String path});

  Future<List<Tag>> tags({required String path});

  Future<List<Remote>> remotes({required String path});

  Future<void> stage({required String path, required List<String> paths});

  Future<void> unstage({required String path, required List<String> paths});

  Future<Commit> commit({
    required String path,
    required String message,
    bool amend,
  });

  Future<void> checkout({required String path, required String branchName});

  Future<void> fetch({required String path, String remoteName});

  Future<void> push({
    required String path,
    String remoteName,
    String? branchName,
  });

  Future<void> dispose({required String path});
}
