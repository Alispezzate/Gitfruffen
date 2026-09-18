import 'package:git_core/src/data/datasources/git_data_source.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/git_repository.dart';
import 'package:git_core/src/domain/entities/remote.dart';
import 'package:git_core/src/domain/entities/signature.dart';

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

  Commit _commit(String sha, String summary, {int parents = 1}) => Commit(
    oid: GitOid(sha),
    message: '$summary\n',
    summary: summary,
    author: _signature,
    committer: _signature,
    parentOids: List.generate(
      parents,
      (i) => GitOid('feedface${i.toString().padLeft(32, '0')}'),
    ),
  );

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
      headCommit: _commit(
        'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678',
        'Init repo',
      ),
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
  List<Commit> get _history => List.generate(60, (index) {
    final sha = (index + 1).toRadixString(16).padLeft(40, '0');
    return _commit(sha, 'Commit #${60 - index}', parents: index == 59 ? 0 : 1);
  });

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
  Future<List<Branch>> branches({required String path}) async {
    await Future<void>.delayed(latency);
    return const [
      Branch(name: 'main', kind: BranchKind.local, isHead: true, ahead: 2),
      Branch(name: 'develop', kind: BranchKind.local, isHead: false, behind: 1),
      Branch(
        name: 'origin/main',
        kind: BranchKind.remote,
        isHead: false,
        ahead: 2,
      ),
    ];
  }

  @override
  Future<List<Tag>> tags({required String path}) async {
    await Future<void>.delayed(latency);
    return const [Tag(name: 'v0.1.0', targetOid: 'a1b2c3d', isAnnotated: true)];
  }

  @override
  Future<List<Remote>> remotes({required String path}) async {
    await Future<void>.delayed(latency);
    return const [
      Remote(name: 'origin', url: 'git@github.com:gitfruffen/gitfruffen.git'),
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
    return _commit('e5f60718293a4b5c6d7e8f9012345678abcdef01', message);
  }

  @override
  Future<void> checkout({
    required String path,
    required String branchName,
  }) async => Future<void>.delayed(latency);

  @override
  Future<void> fetch({
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
  Future<void> dispose({required String path}) async {}
}
