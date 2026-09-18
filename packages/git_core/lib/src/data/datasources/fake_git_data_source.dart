import 'package:git_core/src/data/datasources/git_data_source.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/git_reset_mode.dart';
import 'package:git_core/src/domain/entities/reflog.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/entities/signature.dart';
import 'package:git_core/src/domain/entities/stash.dart';
import 'package:git_core/src/domain/entities/worktree.dart';

/// In-memory [GitDataSource] used for UI development and widget/bloc tests.
///
/// It returns deterministic data and never touches the file system or libgit2,
/// which keeps the presentation layer fully decoupled from the native engine.
final class FakeGitDataSource implements GitDataSource {
  FakeGitDataSource({this.latency = const Duration(milliseconds: 250)});

  final Duration latency;

  DateTime get _now => DateTime.utc(2026, 1, 1, 12);

  Signature get _signature =>
      Signature(name: 'Ada Lovelace', email: 'ada@gitfruffen.dev', when: _now);

  GitRepository _repository(String path) => GitRepository(
    path: path,
    name: path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).last,
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );

  /// Deterministic 40-char SHA for the [n]-th fake commit.
  static String _sha(int n) => n.toRadixString(16).padLeft(40, '0');

  Commit _commit(int id, String summary, {List<int> parents = const []}) =>
      Commit(
        oid: GitOid(_sha(id)),
        message: '$summary\n',
        summary: summary,
        author: _signature,
        committer: _signature,
        parentOids: [for (final parent in parents) GitOid(_sha(parent))],
      );

  /// Parent map for the branchy top of the fake history.
  ///
  /// `feature/graph` branches from 53 and is merged into `main` by 58, while
  /// `develop` (62) branches from 53 and is left unmerged. Commits 52 and
  /// below are linear, so the graph shows a merge loop and an open branch on
  /// top of an otherwise straight history.
  static const Map<int, List<int>> _graphParents = {
    62: [61],
    61: [53],
    60: [59],
    59: [58],
    58: [57, 55],
    57: [56],
    56: [53],
    55: [54],
    54: [53],
    53: [52],
  };

  static const Map<int, String> _namedCommits = {
    62: 'develop: spike',
    61: 'develop: experiment',
    60: 'Update docs',
    59: 'Refine layout',
    58: 'Merge branch feature/graph into main',
    57: 'Polish painter',
    56: 'Continuous lanes',
    55: 'Add graph layout',
    54: 'Wire graph view',
    53: 'Repository workspace',
  };

  List<int> _parentsOf(int id) {
    if (_graphParents.containsKey(id)) {
      return _graphParents[id]!;
    }
    return id > 1 ? [id - 1] : const [];
  }

  String _summaryOf(int id) => _namedCommits[id] ?? 'Commit #$id';

  @override
  Future<GitRepository> open({required String path}) async {
    await Future<void>.delayed(latency);
    return _repository(path);
  }

  @override
  Future<GitRepository> discover({required String startPath}) async =>
      open(path: startPath);

  @override
  Future<GitRepository> clone({
    required String url,
    required String localPath,
  }) async {
    await Future<void>.delayed(latency);
    return _repository(localPath);
  }

  @override
  Future<GitRepository> init({required String path, bool bare = false}) async =>
      open(path: path);

  @override
  Future<RepositoryStatus> status({required String path}) async {
    await Future<void>.delayed(latency);
    return RepositoryStatus(
      currentBranchName: 'main',
      headCommit: _commit(60, _summaryOf(60), parents: _parentsOf(60)),
      changes: const [
        FileChange(
          path: 'lib/main.dart',
          type: FileChangeType.modified,
          staged: true,
          unstaged: false,
          conflicted: false,
        ),
        FileChange(
          path: 'lib/app.dart',
          type: FileChangeType.modified,
          staged: false,
          unstaged: true,
          conflicted: false,
        ),
        FileChange(
          path: 'README.md',
          type: FileChangeType.untracked,
          staged: false,
          unstaged: true,
          conflicted: false,
        ),
      ],
    );
  }

  /// Deterministic commit history, newest first, used to exercise pagination.
  ///
  /// The top commits follow a branchy topology so the graph has a merge and an
  /// open branch to draw during UI development.
  List<Commit> get _history => [
    _commit(62, _summaryOf(62), parents: _parentsOf(62)),
    _commit(61, _summaryOf(61), parents: _parentsOf(61)),
    _commit(60, _summaryOf(60), parents: _parentsOf(60)),
    _commit(59, _summaryOf(59), parents: _parentsOf(59)),
    _commit(58, _summaryOf(58), parents: _parentsOf(58)),
    _commit(57, _summaryOf(57), parents: _parentsOf(57)),
    _commit(56, _summaryOf(56), parents: _parentsOf(56)),
    _commit(55, _summaryOf(55), parents: _parentsOf(55)),
    _commit(54, _summaryOf(54), parents: _parentsOf(54)),
    _commit(53, _summaryOf(53), parents: _parentsOf(53)),
    for (var id = 52; id >= 1; id--)
      _commit(id, _summaryOf(id), parents: _parentsOf(id)),
  ];

  @override
  Future<List<Commit>> log({
    required String path,
    int limit = 100,
    GitOid? from,
  }) async {
    await Future<void>.delayed(latency);
    if (from == null) {
      return _history.take(limit).toList();
    }
    final cursor = _history.indexWhere((commit) => commit.oid == from);
    if (cursor == -1) {
      return const [];
    }
    return _history.skip(cursor + 1).take(limit).toList();
  }

  @override
  Future<List<Commit>> graph({
    required String path,
    int limit = 100,
    GitOid? from,
  }) => log(path: path, limit: limit, from: from);

  @override
  Future<List<Branch>> branches({required String path}) async {
    await Future<void>.delayed(latency);
    return [
      Branch(
        name: 'main',
        kind: BranchKind.local,
        isHead: true,
        targetOid: _sha(60),
        ahead: 2,
      ),
      Branch(
        name: 'develop',
        kind: BranchKind.local,
        isHead: false,
        targetOid: _sha(62),
        behind: 1,
      ),
      Branch(
        name: 'feature/graph',
        kind: BranchKind.local,
        isHead: false,
        targetOid: _sha(55),
      ),
      Branch(
        name: 'origin/main',
        kind: BranchKind.remote,
        isHead: false,
        targetOid: _sha(60),
        ahead: 2,
      ),
      Branch(
        name: 'origin/develop',
        kind: BranchKind.remote,
        isHead: false,
        targetOid: _sha(61),
      ),
    ];
  }

  @override
  Future<List<Tag>> tags({required String path}) async {
    await Future<void>.delayed(latency);
    return [
      Tag(name: 'v0.2.0', targetOid: _sha(57), isAnnotated: true),
      Tag(name: 'v0.1.0', targetOid: _sha(52), isAnnotated: false),
    ];
  }

  @override
  Future<List<Remote>> remotes({required String path}) async {
    await Future<void>.delayed(latency);
    return const [
      Remote(name: 'origin', url: 'git@github.com:gitfruffen/gitfruffen.git'),
    ];
  }

  @override
  Future<List<WorktreeInfo>> worktrees({required String path}) async {
    await Future<void>.delayed(latency);
    return [
      WorktreeInfo(name: 'main', path: path, branch: 'main', isMain: true),
      WorktreeInfo(name: 'hotfix', path: '$path-hotfix', branch: 'hotfix'),
    ];
  }

  @override
  Future<List<StashEntry>> stashes({required String path}) async {
    await Future<void>.delayed(latency);
    return const [
      StashEntry(
        index: 0,
        message: 'WIP on main: refactor repository page',
        oid: GitOid('aaaabbbbccccdddd000000000000000000000000'),
      ),
    ];
  }

  @override
  Future<List<ReflogEntry>> reflog({required String path}) async {
    await Future<void>.delayed(latency);
    final head = GitOid(_sha(60));
    final previous = GitOid(_sha(59));
    return [
      ReflogEntry(
        oldOid: previous,
        newOid: head,
        message: 'commit: ${_summaryOf(60)}',
        committer: _signature,
      ),
      ReflogEntry(
        oldOid: const GitOid('0000000000000000000000000000000000000000'),
        newOid: previous,
        message: 'checkout: moving from feature/graph to main',
        committer: _signature,
      ),
    ];
  }

  @override
  Future<void> stage({
    required String path,
    required List<String> paths,
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> unstage({
    required String path,
    required List<String> paths,
  }) async => Future<void>.delayed(latency);

  @override
  Future<Commit> commit({
    required String path,
    required String message,
    bool amend = false,
  }) async {
    await Future<void>.delayed(latency);
    return _commit(60, message, parents: _parentsOf(60));
  }

  @override
  Future<void> checkout({
    required String path,
    required String branchName,
  }) async => Future<void>.delayed(latency);

  @override
  Future<Branch> createBranch({
    required String path,
    required String name,
    String? targetOid,
    bool checkout = false,
  }) async {
    await Future<void>.delayed(latency);
    return Branch(
      name: name,
      kind: BranchKind.local,
      isHead: checkout,
      targetOid: targetOid,
    );
  }

  @override
  Future<void> deleteBranch({
    required String path,
    required String name,
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> stash({required String path, String? message}) async =>
      Future<void>.delayed(latency);

  @override
  Future<void> applyStash({required String path, required int index}) async =>
      Future<void>.delayed(latency);

  @override
  Future<void> popStash({required String path, required int index}) async =>
      Future<void>.delayed(latency);

  @override
  Future<void> dropStash({required String path, required int index}) async =>
      Future<void>.delayed(latency);

  @override
  Future<WorktreeInfo> addWorktree({
    required String path,
    required String name,
    required String worktreePath,
    String? ref,
  }) async {
    await Future<void>.delayed(latency);
    return WorktreeInfo(name: name, path: worktreePath, branch: ref);
  }

  @override
  Future<void> removeWorktree({
    required String path,
    required String name,
    bool force = false,
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> pruneWorktrees({required String path}) async =>
      Future<void>.delayed(latency);

  @override
  Future<void> fetch({
    required String path,
    String remoteName = 'origin',
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> pull({
    required String path,
    String remoteName = 'origin',
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> push({
    required String path,
    String remoteName = 'origin',
    String? branchName,
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> resetTo({
    required String path,
    required String oid,
    GitResetMode mode = GitResetMode.hard,
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> dispose({required String path}) async {}
}
