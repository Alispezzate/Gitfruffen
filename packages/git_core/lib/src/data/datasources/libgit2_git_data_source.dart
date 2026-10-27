import 'package:git2dart/git2dart.dart' as libgit2;
import 'package:git_core/src/data/datasources/git_data_source.dart';
import 'package:git_core/src/domain/entities/blame.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/diff.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/git_reset_mode.dart';
import 'package:git_core/src/domain/entities/reflog.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/entities/stash.dart';
import 'package:git_core/src/domain/entities/worktree.dart';
import 'package:git_core/src/domain/failures/git_failure.dart';
import 'package:git_core/src/mappers/git_object_mapper.dart';

/// [GitDataSource] backed by libgit2 through the `git2dart` FFI bindings.
///
/// This is the only class in the codebase that may touch native Git resources.
/// Native handles are opened per operation and always released before the
/// future completes.
final class Libgit2GitDataSource implements GitDataSource {
  Libgit2GitDataSource({GitObjectMapper mapper = const GitObjectMapper()})
    : _mapper = mapper;

  final GitObjectMapper _mapper;

  /// Version of the bundled libgit2, useful for diagnostics in the Settings UI.
  String get engineVersion => libgit2.Libgit2.version;

  /// The identity used for commits, stashes and reflogs.
  ///
  /// Falls back to a placeholder when `user.name` / `user.email` are not
  /// configured, so operations still succeed on freshly initialised repos.
  libgit2.Signature _signature(libgit2.Repository repository) {
    try {
      return libgit2.Signature.defaultSignature(repository);
    } on Object {
      return libgit2.Signature.create(
        name: 'Gitfruffen',
        email: 'gitfruffen@localhost',
        time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  /// Resolves the OID the reference named [name] points at, or `null`.
  libgit2.Oid? _referenceTarget(libgit2.Repository repository, String name) {
    try {
      final reference = libgit2.Reference.lookup(repo: repository, name: name);
      try {
        if (reference.type != libgit2.ReferenceType.direct) {
          return null;
        }
        return reference.target;
      } finally {
        reference.free();
      }
    } on Object {
      return null;
    }
  }

  /// Resolves the current HEAD commit, or `null` on an unborn repository.
  libgit2.Commit? _headCommit(libgit2.Repository repository) {
    if (repository.isBranchUnborn) {
      return null;
    }
    try {
      final head = repository.head;
      final target = head.target;
      return libgit2.Commit.lookup(repo: repository, oid: target);
    } on Object {
      return null;
    }
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
  }) async {
    final repository = libgit2.Repository.clone(url: url, localPath: localPath);
    try {
      return _mapper.toRepository(repository);
    } finally {
      repository.free();
    }
  }

  @override
  Future<GitRepository> init({required String path, bool bare = false}) async {
    final repository = libgit2.Repository.initBasic(path: path, bare: bare);
    try {
      return _mapper.toRepository(repository);
    } finally {
      repository.free();
    }
  }

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
    if (repository.isBranchUnborn && from == null) {
      return const [];
    }

    final walker = libgit2.RevWalk(repository);
    try {
      walker.sorting({libgit2.GitSort.time});
      if (from == null) {
        walker.push(repository.head.target);
        return walker.walk(limit: limit).map(_mapper.toCommit).toList();
      }

      // [from] is an exclusive cursor: walk one extra commit and drop it so
      // the next page does not repeat the last commit of the previous one.
      walker.push(repository[from.value]);
      final commits = walker.walk(limit: limit + 1).map(_mapper.toCommit);
      return commits.skip(1).toList();
    } finally {
      walker.free();
    }
  }

  @override
  Future<List<Commit>> graph({
    required String path,
    int limit = 100,
    GitOid? from,
  }) async =>
      _withRepository(path, (repository) => _graphOf(repository, limit, from));

  /// Upper bound on commits walked when paginating the graph with a cursor.
  ///
  /// The graph is ordered topologically, so a cursor cannot reuse the linear
  /// "walk one extra and drop it" trick used by [log]. Instead the walk is
  /// capped and sliced at the cursor, which keeps very large repositories
  /// bounded.
  static const int _maxGraphWalk = 5000;

  /// Walks every local and remote branch so the graph draws the full ref
  /// flow, including branches not yet merged into HEAD.
  List<Commit> _graphOf(
    libgit2.Repository repository,
    int limit,
    GitOid? from,
  ) {
    if (repository.isBranchUnborn && from == null) {
      return const [];
    }
    final walker = libgit2.RevWalk(repository);
    try {
      walker
        ..sorting({libgit2.GitSort.topological, libgit2.GitSort.time})
        ..pushGlob('refs/heads/*')
        ..pushGlob('refs/remotes/*')
        ..pushHead();

      if (from == null) {
        return walker.walk(limit: limit).map(_mapper.toCommit).toList();
      }

      final all = walker.walk(limit: _maxGraphWalk);
      final cursor = all.indexWhere((commit) => commit.oid.sha == from.value);
      if (cursor == -1) {
        return const [];
      }
      return all.skip(cursor + 1).take(limit).map(_mapper.toCommit).toList();
    } finally {
      walker.free();
    }
  }

  @override
  Future<List<BlameLine>> blameFile({
    required String path,
    required String filePath,
    GitOid? at,
  }) async =>
      _withRepository(path, (repository) => _blameOf(repository, filePath, at));

  List<BlameLine> _blameOf(
    libgit2.Repository repository,
    String filePath,
    GitOid? at,
  ) {
    final blame = libgit2.Blame.file(
      repo: repository,
      path: filePath,
      newestCommit: at == null ? null : repository[at.value],
    );
    try {
      final summaryByCommit = <String, String>{};
      final lines = <BlameLine>[];
      for (final hunk in blame) {
        final committer = hunk.finalCommitter;
        if (committer == null) {
          continue;
        }
        final commitSha = hunk.finalCommitOid.sha;
        final summary = summaryByCommit[commitSha] ??= _summaryOf(
          repository: repository,
          oid: hunk.finalCommitOid,
        );
        final author = _mapper.toSignature(committer);
        for (var offset = 0; offset < hunk.linesCount; offset++) {
          lines.add(
            BlameLine(
              line: hunk.finalStartLineNumber + offset,
              commitOid: GitOid(commitSha),
              summary: summary,
              author: author,
              isBoundary: hunk.isBoundary,
            ),
          );
        }
      }
      return lines;
    } finally {
      blame.free();
    }
  }

  String _summaryOf({
    required libgit2.Repository repository,
    required libgit2.Oid oid,
  }) {
    final commit = libgit2.Commit.lookup(repo: repository, oid: oid);
    try {
      return commit.summary;
    } finally {
      commit.free();
    }
  }

  /// Upper bound on commits walked when looking for a file's history.
  static const int _maxFileHistoryWalk = 2000;

  @override
  Future<List<Commit>> fileHistory({
    required String path,
    required String filePath,
    int limit = 50,
  }) async => _withRepository(
    path,
    (repository) => _fileHistoryOf(repository, filePath, limit),
  );

  // ponytail: follows only the current path; add rename tracking if users hit it.
  List<Commit> _fileHistoryOf(
    libgit2.Repository repository,
    String filePath,
    int limit,
  ) {
    if (limit <= 0 || repository.isBranchUnborn) {
      return const [];
    }

    final walker = libgit2.RevWalk(repository);
    try {
      walker
        ..sorting({libgit2.GitSort.time})
        ..pushHead();
      final walked = walker.walk(limit: _maxFileHistoryWalk);
      try {
        final history = <Commit>[];
        for (final commit in walked) {
          if (_commitTouchesPath(repository, commit, filePath)) {
            history.add(_mapper.toCommit(commit));
            if (history.length == limit) {
              break;
            }
          }
        }
        return history;
      } finally {
        for (final commit in walked) {
          commit.free();
        }
      }
    } finally {
      walker.free();
    }
  }

  bool _commitTouchesPath(
    libgit2.Repository repository,
    libgit2.Commit commit,
    String filePath,
  ) {
    libgit2.Tree? newTree;
    libgit2.Tree? parentTree;
    libgit2.Commit? parent;
    try {
      newTree = commit.tree;
      final newOid = _pathOid(newTree, filePath);
      if (commit.parents.isEmpty) {
        return newOid != null;
      }
      parent = commit.parent(0);
      parentTree = parent.tree;
      return _pathOid(parentTree, filePath) != newOid;
    } finally {
      parentTree?.free();
      newTree?.free();
      parent?.free();
    }
  }

  /// OID of [filePath] in [tree], or `null` when the path is absent.
  String? _pathOid(libgit2.Tree tree, String filePath) {
    final libgit2.TreeEntry entry;
    try {
      entry = tree[filePath];
    } on Object {
      return null;
    }
    try {
      return entry.oid.sha;
    } finally {
      // Entries looked up by path own their native pointer; name lookups do not.
      if (filePath.contains('/')) {
        entry.free();
      }
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
      if (reference.type != libgit2.ReferenceType.direct) {
        return null;
      }

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
        if (upstream.type != libgit2.ReferenceType.direct) {
          return base;
        }
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
  Future<List<WorktreeInfo>> worktrees({required String path}) async =>
      _withRepository(path, _worktreesOf);

  List<WorktreeInfo> _worktreesOf(libgit2.Repository repository) {
    final main = WorktreeInfo(
      name: repository.isBare ? repository.path : 'main',
      path: repository.isBare ? repository.path : repository.workdir,
      isMain: true,
    );

    return [
      main,
      for (final name in libgit2.Worktree.list(repository))
        ?_toWorktree(repository, name),
    ];
  }

  WorktreeInfo? _toWorktree(libgit2.Repository repository, String name) {
    try {
      final worktree = libgit2.Worktree.lookup(repo: repository, name: name);
      try {
        return _mapper.toWorktree(worktree);
      } finally {
        worktree.free();
      }
    } on Object {
      return null;
    }
  }

  @override
  Future<List<StashEntry>> stashes({required String path}) async =>
      _withRepository(path, _stashesOf);

  List<StashEntry> _stashesOf(libgit2.Repository repository) => [
    for (final stash in libgit2.Stash.list(repository)) _mapper.toStash(stash),
  ];

  @override
  Future<List<ReflogEntry>> reflog({required String path}) async =>
      _withRepository(path, _reflogOf);

  List<ReflogEntry> _reflogOf(libgit2.Repository repository) {
    final reference = _headReference(repository);
    if (reference == null) {
      return const [];
    }
    try {
      final log = reference.log;
      try {
        return log.map(_mapper.toReflog).toList();
      } finally {
        log.free();
      }
    } on Object {
      return const [];
    } finally {
      reference.free();
    }
  }

  libgit2.Reference? _headReference(libgit2.Repository repository) {
    try {
      final head = repository.head;
      return head.type == libgit2.ReferenceType.direct ? head : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> stage({
    required String path,
    required List<String> paths,
  }) async => _withRepository(path, (repository) {
    repository.index
      ..addAll(paths)
      ..write();
  });

  @override
  Future<void> unstage({
    required String path,
    required List<String> paths,
  }) async => _withRepository(path, (repository) {
    final head = _headCommit(repository);
    repository.resetDefault(oid: head?.oid, pathspec: paths);
  });

  @override
  Future<Commit> commit({
    required String path,
    required String message,
    bool amend = false,
  }) async => _withRepository(path, (repository) {
    final signature = _signature(repository);
    final index = repository.index;
    final treeOid = index.writeTree(repository);
    final tree = libgit2.Tree.lookup(repo: repository, oid: treeOid);
    try {
      final head = _headCommit(repository);
      final oid = amend && head != null
          ? libgit2.Commit.amend(
              repo: repository,
              commit: head,
              updateRef: 'HEAD',
              author: signature,
              committer: signature,
              tree: tree,
              message: message,
            )
          : libgit2.Commit.create(
              repo: repository,
              updateRef: 'HEAD',
              author: signature,
              committer: signature,
              message: message,
              tree: tree,
              parents: head == null ? const [] : [head],
            );
      final commit = libgit2.Commit.lookup(repo: repository, oid: oid);
      try {
        return _mapper.toCommit(commit);
      } finally {
        commit.free();
      }
    } finally {
      tree.free();
    }
  });

  @override
  Future<void> checkout({
    required String path,
    required String branchName,
  }) async => _withRepository(path, (repository) {
    repository.setHead('refs/heads/$branchName');
    libgit2.Checkout.head(
      repo: repository,
      strategy: {libgit2.GitCheckout.safe, libgit2.GitCheckout.recreateMissing},
    );
  });

  @override
  Future<Branch> createBranch({
    required String path,
    required String name,
    String? targetOid,
    bool checkout = false,
  }) async => _withRepository(path, (repository) {
    final target = targetOid != null
        ? libgit2.Commit.lookup(repo: repository, oid: repository[targetOid])
        : _headCommit(repository);
    if (target == null) {
      throw const UnexpectedGitFailure(
        'Cannot create a branch without commits',
      );
    }
    final targetSha = target.oid.sha;
    final branch = libgit2.Branch.create(
      repo: repository,
      name: name,
      target: target,
    );
    try {
      if (checkout) {
        repository.setHead('refs/heads/$name');
        libgit2.Checkout.head(
          repo: repository,
          strategy: {
            libgit2.GitCheckout.safe,
            libgit2.GitCheckout.recreateMissing,
          },
        );
      }
      return Branch(
        name: name,
        kind: BranchKind.local,
        isHead: checkout,
        targetOid: targetSha,
      );
    } finally {
      branch.free();
      target.free();
    }
  });

  @override
  Future<void> deleteBranch({
    required String path,
    required String name,
  }) async => _withRepository(
    path,
    (repository) => libgit2.Branch.delete(repo: repository, name: name),
  );

  @override
  Future<void> stash({required String path, String? message}) async =>
      _withRepository(path, (repository) {
        libgit2.Stash.create(
          repo: repository,
          stasher: _signature(repository),
          message: message,
        );
      });

  @override
  Future<void> applyStash({required String path, required int index}) async =>
      _withRepository(
        path,
        (repository) => libgit2.Stash.apply(repo: repository, index: index),
      );

  @override
  Future<void> popStash({required String path, required int index}) async =>
      _withRepository(
        path,
        (repository) => libgit2.Stash.pop(repo: repository, index: index),
      );

  @override
  Future<void> dropStash({required String path, required int index}) async =>
      _withRepository(
        path,
        (repository) => libgit2.Stash.drop(repo: repository, index: index),
      );

  @override
  Future<WorktreeInfo> addWorktree({
    required String path,
    required String name,
    required String worktreePath,
    String? ref,
  }) async => _withRepository(path, (repository) {
    libgit2.Reference? reference;
    if (ref != null) {
      reference = libgit2.Reference.lookup(
        repo: repository,
        name: 'refs/heads/$ref',
      );
    }
    try {
      final worktree = libgit2.Worktree.create(
        repo: repository,
        name: name,
        path: worktreePath,
        ref: reference,
      );
      try {
        return _mapper.toWorktree(worktree, branch: ref);
      } finally {
        worktree.free();
      }
    } finally {
      reference?.free();
    }
  });

  @override
  Future<void> removeWorktree({
    required String path,
    required String name,
    bool force = false,
  }) async => _withRepository(path, (repository) {
    final worktree = libgit2.Worktree.lookup(repo: repository, name: name);
    try {
      if (worktree.isLocked) {
        worktree.unlock();
      }
      worktree.prune(
        force ? const {libgit2.GitWorktree.pruneWorkingTree} : null,
      );
    } finally {
      worktree.free();
    }
  });

  @override
  Future<void> pruneWorktrees({required String path}) async => _withRepository(
    path,
    (repository) {
      for (final name in libgit2.Worktree.list(repository)) {
        final worktree = libgit2.Worktree.lookup(repo: repository, name: name);
        try {
          if (worktree.isPrunable) {
            worktree.prune();
          }
        } finally {
          worktree.free();
        }
      }
    },
  );

  @override
  Future<void> fetch({
    required String path,
    String remoteName = 'origin',
  }) async => _withRepository(path, (repository) {
    final remote = libgit2.Remote.lookup(repo: repository, name: remoteName);
    try {
      remote.fetch();
    } finally {
      remote.free();
    }
  });

  @override
  Future<void> pull({
    required String path,
    String remoteName = 'origin',
  }) async => _withRepository(path, (repository) {
    final remote = libgit2.Remote.lookup(repo: repository, name: remoteName);
    try {
      remote.fetch();
    } finally {
      remote.free();
    }

    final branchName = _currentBranchName(repository);
    final remoteRef = branchName == null
        ? null
        : _referenceTarget(repository, 'refs/remotes/$remoteName/$branchName');
    if (remoteRef == null || branchName == null) {
      return;
    }

    final analysis = libgit2.Merge.analysis(
      repo: repository,
      theirHead: remoteRef,
    );
    if (analysis.result.contains(libgit2.GitMergeAnalysis.upToDate)) {
      return;
    }
    if (analysis.result.contains(libgit2.GitMergeAnalysis.fastForward)) {
      final reference = libgit2.Reference.create(
        repo: repository,
        name: 'refs/heads/$branchName',
        target: remoteRef,
        force: true,
        logMessage: 'pull: fast-forward',
      );
      try {
        libgit2.Checkout.head(
          repo: repository,
          strategy: {
            libgit2.GitCheckout.safe,
            libgit2.GitCheckout.recreateMissing,
          },
        );
      } finally {
        reference.free();
      }
      return;
    }

    final annotated = libgit2.AnnotatedCommit.lookup(
      repo: repository,
      oid: remoteRef,
    );
    try {
      libgit2.Merge.commit(repo: repository, commit: annotated);
    } finally {
      annotated.free();
    }
  });

  String? _currentBranchName(libgit2.Repository repository) {
    if (repository.isBranchUnborn || repository.isHeadDetached) {
      return null;
    }
    try {
      return repository.head.shorthand;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> push({
    required String path,
    String remoteName = 'origin',
    String? branchName,
  }) async => _withRepository(path, (repository) {
    final branch = branchName ?? _currentBranchName(repository);
    final remote = libgit2.Remote.lookup(repo: repository, name: remoteName);
    try {
      remote.push(
        refspecs: [
          if (branch != null)
            'refs/heads/$branch:refs/heads/$branch'
          else
            'HEAD:refs/heads/HEAD',
        ],
      );
    } finally {
      remote.free();
    }
  });

  @override
  Future<void> resetTo({
    required String path,
    required String oid,
    GitResetMode mode = GitResetMode.hard,
  }) async => _withRepository(path, (repository) {
    repository.reset(
      oid: repository[oid],
      resetType: _mapper.toResetMode(mode),
      strategy: mode == GitResetMode.hard
          ? {
              libgit2.GitCheckout.force,
              libgit2.GitCheckout.recreateMissing,
              libgit2.GitCheckout.removeUntracked,
            }
          : {libgit2.GitCheckout.safe, libgit2.GitCheckout.recreateMissing},
    );
  });

  @override
  Future<void> dispose({required String path}) async {}

  /// Builds the flag set shared by the diff methods.
  Set<libgit2.GitDiff> _diffFlags({
    required bool ignoreWhitespace,
    bool includeUntracked = false,
  }) => {
    if (includeUntracked) ...{
      libgit2.GitDiff.includeUntracked,
      libgit2.GitDiff.recurseUntrackedDirs,
      libgit2.GitDiff.showUntrackedContent,
    },
    if (ignoreWhitespace) libgit2.GitDiff.ignoreWhitespaceChange,
  };

  @override
  Future<DiffResult> diffCommit({
    required String path,
    required GitOid oid,
    bool ignoreWhitespace = false,
    int contextLines = 3,
  }) async => _withRepository(path, (repository) {
    final commit = libgit2.Commit.lookup(
      repo: repository,
      oid: repository[oid.value],
    );
    libgit2.Commit? parent;
    libgit2.Tree? oldTree;
    libgit2.Tree? newTree;
    try {
      newTree = commit.tree;
      if (commit.parents.isNotEmpty) {
        parent = commit.parent(0);
        oldTree = parent.tree;
      }
      final diff = libgit2.Diff.treeToTree(
        repo: repository,
        oldTree: oldTree,
        newTree: newTree,
        flags: _diffFlags(ignoreWhitespace: ignoreWhitespace),
        contextLines: contextLines,
      );
      try {
        if (diff.length > 0) {
          diff.findSimilar();
        }
        return _toDiffResult(diff);
      } finally {
        diff.free();
      }
    } finally {
      oldTree?.free();
      newTree?.free();
      parent?.free();
      commit.free();
    }
  });

  @override
  Future<DiffResult> diffWorkingTree({
    required String path,
    required bool staged,
    bool ignoreWhitespace = false,
    int contextLines = 3,
  }) async => _withRepository(path, (repository) {
    final index = repository.index;
    libgit2.Commit? head;
    libgit2.Tree? headTree;
    try {
      head = _headCommit(repository);
      headTree = head?.tree;
      final flags = _diffFlags(
        ignoreWhitespace: ignoreWhitespace,
        includeUntracked: !staged,
      );
      final diff = staged
          ? libgit2.Diff.treeToIndex(
              repo: repository,
              tree: headTree,
              index: index,
              flags: flags,
              contextLines: contextLines,
            )
          : libgit2.Diff.indexToWorkdir(
              repo: repository,
              index: index,
              flags: flags,
              contextLines: contextLines,
            );
      try {
        if (staged && diff.length > 0) {
          diff.findSimilar();
        }
        return _toDiffResult(diff);
      } finally {
        diff.free();
      }
    } finally {
      headTree?.free();
      head?.free();
      index.free();
    }
  });

  /// Maps a native diff into immutable domain entities.
  ///
  /// Every patch is released as soon as it has been mapped; the caller owns
  /// and frees [diff].
  DiffResult _toDiffResult(libgit2.Diff diff) {
    final files = <DiffFile>[];
    for (var index = 0; index < diff.length; index++) {
      final patch = libgit2.Patch.fromDiff(diff: diff, index: index);
      try {
        files.add(_toDiffFile(patch));
      } finally {
        patch.free();
      }
    }
    return DiffResult(files: files);
  }

  DiffFile _toDiffFile(libgit2.Patch patch) {
    final delta = patch.delta;
    final newPath = delta.newFile.path;
    final path = newPath.isEmpty ? delta.oldFile.path : newPath;
    final oldPath = delta.oldFile.path;
    final stats = patch.stats;

    return DiffFile(
      path: path,
      oldPath: oldPath.isNotEmpty && oldPath != path ? oldPath : null,
      changeType: _changeType(delta.status),
      isBinary: delta.flags.contains(libgit2.GitDiffFlag.binary),
      insertions: stats.insertions,
      deletions: stats.deletions,
      hunks: [
        for (final hunk in patch.hunks)
          DiffHunk(
            header: hunk.header.trim(),
            lines: hunk.lines.map(_toDiffLine).nonNulls.toList(),
          ),
      ],
    );
  }

  DiffLine? _toDiffLine(libgit2.DiffLine line) {
    final kind = _lineKind(line.origin);
    if (kind == null) {
      return null;
    }
    return DiffLine(
      kind: kind,
      content: _withoutTrailingNewline(line.content),
      oldLine: _lineNumber(line.oldLineNumber),
      newLine: _lineNumber(line.newLineNumber),
    );
  }

  DiffLineKind? _lineKind(libgit2.GitDiffLine origin) => switch (origin) {
    libgit2.GitDiffLine.context => DiffLineKind.context,
    libgit2.GitDiffLine.addition => DiffLineKind.added,
    libgit2.GitDiffLine.deletion => DiffLineKind.removed,
    _ => null,
  };

  int? _lineNumber(int value) => value < 0 ? null : value;

  String _withoutTrailingNewline(String content) => content.endsWith('\n')
      ? content.substring(0, content.length - 1)
      : content;

  FileChangeType _changeType(libgit2.GitDelta delta) => switch (delta) {
    libgit2.GitDelta.added ||
    libgit2.GitDelta.untracked => FileChangeType.added,
    libgit2.GitDelta.deleted => FileChangeType.deleted,
    libgit2.GitDelta.renamed ||
    libgit2.GitDelta.copied => FileChangeType.renamed,
    libgit2.GitDelta.conflicted => FileChangeType.conflicted,
    _ => FileChangeType.modified,
  };
}
