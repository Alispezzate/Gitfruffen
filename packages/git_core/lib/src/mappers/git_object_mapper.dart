import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/entities/signature.dart';
import 'package:git_core/src/domain/failures/git_failure.dart';

import 'package:git2dart/git2dart.dart' as libgit2;

/// Converts native `git2dart` objects into immutable domain entities.
///
/// In the Pine architecture this sits in the `mappers` layer and is injected
/// above datasources and repositories. Keeping the translation here means the
/// rest of the app only ever sees `Equatable` entities.
final class GitObjectMapper {
  const GitObjectMapper();

  GitRepository toRepository(libgit2.Repository repo) {
    final workdir = repo.workdir;
    final path = workdir.isEmpty ? repo.path : workdir;
    return GitRepository(
      path: path,
      name: _repoName(path),
      isBare: repo.isBare,
      isHeadDetached: repo.isHeadDetached,
      isUnborn: repo.isBranchUnborn,
    );
  }

  Commit toCommit(libgit2.Commit commit) => Commit(
    oid: GitOid(commit.oid.sha),
    message: commit.message,
    summary: commit.summary,
    author: toSignature(commit.author),
    committer: toSignature(commit.committer),
    parentOids: commit.parents.map((oid) => GitOid(oid.sha)).toList(),
  );

  Signature toSignature(libgit2.Signature signature) => Signature(
    name: signature.name,
    email: signature.email,
    when: DateTime.fromMillisecondsSinceEpoch(signature.time * 1000),
  );

  Tag toTag(libgit2.Tag tag) => Tag(
    name: tag.name,
    targetOid: tag.targetOid.sha,
    isAnnotated: tag.message.isNotEmpty,
    message: tag.message.isEmpty ? null : tag.message,
  );

  Remote toRemote(libgit2.Remote remote) => Remote(
    name: remote.name,
    url: remote.url,
    pushUrl: remote.pushUrl.isEmpty ? null : remote.pushUrl,
  );

  /// Maps a single working-tree entry reported by libgit2.
  ///
  /// [flags] is the raw set of `git_status_t` values for one path. Ignored
  /// entries are expected to be filtered out by the caller.
  FileChange toFileChange(String path, Set<libgit2.GitStatus> flags) {
    final conflicted = flags.contains(libgit2.GitStatus.conflicted);
    final staged = flags.any(_isIndexFlag);
    final unstaged = flags.any(_isWorkdirFlag);

    return FileChange(
      path: path,
      type: _changeType(flags),
      staged: staged,
      unstaged: unstaged,
      conflicted: conflicted,
    );
  }

  /// Maps the raw status map returned by libgit2 into a domain [RepositoryStatus].
  ///
  /// Ignored entries are dropped: they are never shown as working-tree changes.
  RepositoryStatus toStatus({
    required String? branchName,
    required Commit? headCommit,
    required Map<String, Set<libgit2.GitStatus>> rawStatus,
  }) => RepositoryStatus(
    currentBranchName: branchName,
    headCommit: headCommit,
    changes: [
      for (final entry in rawStatus.entries)
        if (!entry.value.contains(libgit2.GitStatus.ignored))
          toFileChange(entry.key, entry.value),
    ],
  );

  bool _isIndexFlag(libgit2.GitStatus status) => switch (status) {
    libgit2.GitStatus.indexNew ||
    libgit2.GitStatus.indexModified ||
    libgit2.GitStatus.indexDeleted ||
    libgit2.GitStatus.indexRenamed ||
    libgit2.GitStatus.indexTypeChange => true,
    _ => false,
  };

  bool _isWorkdirFlag(libgit2.GitStatus status) => switch (status) {
    libgit2.GitStatus.wtNew ||
    libgit2.GitStatus.wtModified ||
    libgit2.GitStatus.wtDeleted ||
    libgit2.GitStatus.wtTypeChange ||
    libgit2.GitStatus.wtRenamed ||
    libgit2.GitStatus.wtUnreadable => true,
    _ => false,
  };

  FileChangeType _changeType(Set<libgit2.GitStatus> flags) {
    if (flags.contains(libgit2.GitStatus.conflicted)) {
      return FileChangeType.conflicted;
    }
    if (flags.contains(libgit2.GitStatus.indexRenamed) ||
        flags.contains(libgit2.GitStatus.wtRenamed)) {
      return FileChangeType.renamed;
    }
    if (flags.contains(libgit2.GitStatus.indexDeleted) ||
        flags.contains(libgit2.GitStatus.wtDeleted)) {
      return FileChangeType.deleted;
    }
    if (flags.contains(libgit2.GitStatus.indexNew)) {
      return FileChangeType.added;
    }
    if (flags.contains(libgit2.GitStatus.wtNew)) {
      return FileChangeType.untracked;
    }
    return FileChangeType.modified;
  }

  /// Maps any engine error to a typed [GitFailure].
  GitFailure toFailure(Object error, [StackTrace? stackTrace]) =>
      switch (error) {
        libgit2.Git2DartError() => UnexpectedGitFailure(
          error.message,
          cause: error,
        ),
        _ => UnexpectedGitFailure('$error', cause: error),
      };

  String _repoName(String path) =>
      path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).lastOrNull ??
      path;
}
