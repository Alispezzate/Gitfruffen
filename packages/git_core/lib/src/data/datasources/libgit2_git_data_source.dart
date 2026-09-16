import 'package:git2dart/git2dart.dart' as libgit2;
import 'package:git_core/src/data/datasources/git_data_source.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/failures/git_failure.dart';
import 'package:git_core/src/mappers/git_object_mapper.dart';

/// [GitDataSource] backed by libgit2 through the `git2dart` FFI bindings.
///
/// This is the only class in the codebase that may touch native Git resources.
/// Native handles are opened per operation and always released before the
/// future completes.
///
/// Read operations (open, discover, status, log, branches, tags, remotes) are
/// implemented. Mutating operations (init, clone, stage, unstage, commit,
/// checkout, fetch, push) still fail fast with an [UnexpectedGitFailure].
final class Libgit2GitDataSource implements GitDataSource {
  Libgit2GitDataSource({GitObjectMapper mapper = const GitObjectMapper()})
    : _mapper = mapper;

  final GitObjectMapper _mapper;

  /// Version of the bundled libgit2, useful for diagnostics in the Settings UI.
  String get engineVersion => libgit2.Libgit2.version;

  Never _notImplemented(String operation) {
    throw UnexpectedGitFailure(
      'Libgit2GitDataSource.$operation is not implemented yet.',
    );
  }

  libgit2.Repository _openRepository(String path) {
    try {
      return libgit2.Repository.open(path);
    } on Object catch (error) {
      throw RepositoryNotFoundFailure(
        'Not a Git repository at $path',
        cause: error,
      );
    }
  }

  /// Runs [body] with a repository opened at [path], always releasing the
  /// native handle and mapping engine errors to typed domain failures.
  T _withRepository<T>(
    String path,
    T Function(libgit2.Repository repository) body,
  ) {
    final repository = _openRepository(path);
    try {
      return body(repository);
    } on GitFailure {
      rethrow;
    } on Object catch (error) {
      throw _mapper.toFailure(error);
    } finally {
      repository.free();
    }
  }

  @override
  Future<GitRepository> open({required String path}) async =>
      _withRepository(path, _mapper.toRepository);

  @override
  Future<GitRepository> discover({required String startPath}) async {
    final String path;
    try {
      path = libgit2.Repository.discover(startPath: startPath);
    } on Object catch (error) {
      throw RepositoryNotFoundFailure(
        'No Git repository found at or above $startPath',
        cause: error,
      );
    }
    return _withRepository(path, _mapper.toRepository);
  }

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
      _withRepository(path, _statusOf);

  RepositoryStatus _statusOf(libgit2.Repository repository) {
    final isUnborn = repository.isBranchUnborn;
    final branchName = isUnborn || repository.isHeadDetached
        ? null
        : repository.head.shorthand;

    Commit? headCommit;
    if (!isUnborn) {
      try {
        headCommit = _mapper.toCommit(repository.headCommit);
      } on Object {
        headCommit = null;
      }
    }

    return _mapper.toStatus(
      branchName: branchName,
      headCommit: headCommit,
      rawStatus: repository.status,
    );
  }

  @override
  Future<List<Commit>> log({
    required String path,
    int limit = 100,
    GitOid? from,
  }) async =>
      _withRepository(path, (repository) => _logOf(repository, limit, from));

  List<Commit> _logOf(libgit2.Repository repository, int limit, GitOid? from) {
    if (repository.isBranchUnborn && from == null) return const [];

    final start = from == null
        ? repository.head.target
        : repository[from.value];
    final walker = libgit2.RevWalk(repository);
    try {
      walker.sorting({libgit2.GitSort.time});
      walker.push(start);
      return walker.walk(limit: limit).map(_mapper.toCommit).toList();
    } finally {
      walker.free();
    }
  }

  @override
  Future<List<Branch>> branches({required String path}) async =>
      _withRepository(path, _branchesOf);

  /// Lists local and remote branches.
  ///
  /// Branches are read through references rather than `Branch.list` because
  /// symbolic remote refs such as `origin/HEAD` have no direct target, and
  /// dereferencing them through `Branch.target` crashes inside libgit2. Such
  /// symbolic entries are skipped.
  List<Branch> _branchesOf(libgit2.Repository repository) {
    const localPrefix = 'refs/heads/';
    const remotePrefix = 'refs/remotes/';
    final headName = _headReferenceName(repository);

    return [
      for (final name in repository.references)
        if (name.startsWith(localPrefix))
          ?_toBranch(
            repository,
            name: name,
            displayName: name.substring(localPrefix.length),
            kind: BranchKind.local,
            isHead: name == headName,
          )
        else if (name.startsWith(remotePrefix))
          ?_toBranch(
            repository,
            name: name,
            displayName: name.substring(remotePrefix.length),
            kind: BranchKind.remote,
            isHead: false,
          ),
    ];
  }

  String? _headReferenceName(libgit2.Repository repository) {
    try {
      final head = repository.head;
      try {
        return head.type == libgit2.ReferenceType.direct ? head.name : null;
      } finally {
        head.free();
      }
    } on Object {
      return null;
    }
  }

  Branch? _toBranch(
    libgit2.Repository repository, {
    required String name,
    required String displayName,
    required BranchKind kind,
    required bool isHead,
  }) {
    final reference = libgit2.Reference.lookup(repo: repository, name: name);
    try {
      if (reference.type != libgit2.ReferenceType.direct) return null;

      final target = reference.target;
      if (kind == BranchKind.local) {
        return _toLocalBranch(
          repository,
          name: name,
          displayName: displayName,
          isHead: isHead,
          target: target,
        );
      }
      return Branch(
        name: displayName,
        kind: kind,
        isHead: isHead,
        targetOid: target.sha,
      );
    } finally {
      reference.free();
    }
  }

  Branch _toLocalBranch(
    libgit2.Repository repository, {
    required String name,
    required String displayName,
    required bool isHead,
    required libgit2.Oid target,
  }) {
    final base = Branch(
      name: displayName,
      kind: BranchKind.local,
      isHead: isHead,
      targetOid: target.sha,
    );

    final branch = libgit2.Branch.lookup(repo: repository, name: displayName);
    try {
      final upstream = branch.upstream;
      try {
        if (upstream.type != libgit2.ReferenceType.direct) return base;
        final counts = repository.aheadBehind(
          local: target,
          upstream: upstream.target,
        );
        return Branch(
          name: base.name,
          kind: base.kind,
          isHead: base.isHead,
          targetOid: base.targetOid,
          upstream: upstream.shorthand,
          ahead: counts[0],
          behind: counts[1],
        );
      } finally {
        upstream.free();
      }
    } on Object {
      return base;
    } finally {
      branch.free();
    }
  }

  @override
  Future<List<Tag>> tags({required String path}) async =>
      _withRepository(path, _tagsOf);

  List<Tag> _tagsOf(libgit2.Repository repository) => [
    for (final name in repository.tags) ?_toTag(repository, name),
  ];

  Tag? _toTag(libgit2.Repository repository, String name) {
    try {
      final reference = libgit2.Reference.lookup(
        repo: repository,
        name: 'refs/tags/$name',
      );
      try {
        final peeled = reference.peeledTarget;
        if (peeled == null) {
          return Tag(
            name: name,
            targetOid: reference.target.sha,
            isAnnotated: false,
          );
        }
        final tag = libgit2.Tag.lookup(repo: repository, oid: reference.target);
        try {
          return _mapper.toTag(tag);
        } finally {
          tag.free();
        }
      } finally {
        reference.free();
      }
    } on Object {
      return null;
    }
  }

  @override
  Future<List<Remote>> remotes({required String path}) async =>
      _withRepository(path, _remotesOf);

  List<Remote> _remotesOf(libgit2.Repository repository) => [
    for (final name in libgit2.Remote.list(repository))
      _toRemote(repository, name),
  ];

  Remote _toRemote(libgit2.Repository repository, String name) {
    final remote = libgit2.Remote.lookup(repo: repository, name: name);
    try {
      return _mapper.toRemote(remote);
    } finally {
      remote.free();
    }
  }

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
