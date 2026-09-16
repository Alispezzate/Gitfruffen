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

  Branch toBranch(libgit2.Branch branch, {required BranchKind kind}) => Branch(
    name: branch.name,
    kind: kind,
    isHead: branch.isHead,
    targetOid: branch.target.sha,
  );

  Tag toTag(libgit2.Tag tag) => Tag(
    name: tag.name,
    targetOid: tag.targetOid.sha,
    isAnnotated: tag.message.isNotEmpty,
    message: tag.message.isEmpty ? null : tag.message,
  );

  Remote toRemote(libgit2.Remote remote) =>
      Remote(name: remote.name, url: remote.url);

  /// Maps any engine error to a typed [GitFailure].
  GitFailure toFailure(Object error, [StackTrace? stackTrace]) =>
      switch (error) {
        libgit2.Git2DartError() => UnexpectedGitFailure(
          error.message,
          cause: error,
        ),
        _ => UnexpectedGitFailure('Unexpected Git error', cause: error),
      };

  String _repoName(String path) =>
      path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).lastOrNull ??
      path;
}
