import 'package:flutter_test/flutter_test.dart';
import 'package:git2dart/git2dart.dart' as libgit2;
import 'package:git_core/git_core.dart';

void main() {
  group('GitOid', () {
    test('exposes an abbreviated form', () {
      const oid = GitOid('a1b2c3d4e5f60718293a4b5c6d7e8f9012345678');
      expect(oid.short, 'a1b2c3d');
    });

    test('is value-equal', () {
      expect(const GitOid('abcd1234'), const GitOid('abcd1234'));
    });
  });

  group('RepositoryStatus', () {
    test('counts staged, unstaged and conflicted changes', () {
      const status = RepositoryStatus(
        currentBranchName: 'main',
        headCommit: null,
        changes: [
          FileChange(
            path: 'a.dart',
            type: FileChangeType.modified,
            staged: true,
            unstaged: false,
            conflicted: false,
          ),
          FileChange(
            path: 'b.dart',
            type: FileChangeType.modified,
            staged: false,
            unstaged: true,
            conflicted: false,
          ),
          FileChange(
            path: 'c.dart',
            type: FileChangeType.conflicted,
            staged: false,
            unstaged: false,
            conflicted: true,
          ),
        ],
      );

      expect(status.stagedCount, 1);
      expect(status.unstagedCount, 1);
      expect(status.conflictedCount, 1);
      expect(status.isClean, isFalse);
    });
  });

  group('GitObjectMapper.toFileChange', () {
    const mapper = GitObjectMapper();

    test('maps a staged addition', () {
      final change = mapper.toFileChange('a.dart', {
        libgit2.GitStatus.indexNew,
      });

      expect(change.type, FileChangeType.added);
      expect(change.staged, isTrue);
      expect(change.unstaged, isFalse);
    });

    test('maps an untracked file', () {
      final change = mapper.toFileChange('a.dart', {libgit2.GitStatus.wtNew});

      expect(change.type, FileChangeType.untracked);
      expect(change.unstaged, isTrue);
    });

    test('maps a working-tree modification as modified', () {
      final change = mapper.toFileChange('a.dart', {
        libgit2.GitStatus.wtModified,
      });

      expect(change.type, FileChangeType.modified);
      expect(change.staged, isFalse);
      expect(change.unstaged, isTrue);
    });

    test('prioritises conflict over everything else', () {
      final change = mapper.toFileChange('a.dart', {
        libgit2.GitStatus.conflicted,
        libgit2.GitStatus.indexModified,
      });

      expect(change.type, FileChangeType.conflicted);
      expect(change.conflicted, isTrue);
    });

    test('maps a rename', () {
      final change = mapper.toFileChange('a.dart', {
        libgit2.GitStatus.indexRenamed,
      });

      expect(change.type, FileChangeType.renamed);
      expect(change.staged, isTrue);
    });

    test('maps a deletion', () {
      final change = mapper.toFileChange('a.dart', {
        libgit2.GitStatus.wtDeleted,
      });

      expect(change.type, FileChangeType.deleted);
    });
  });

  group('GitObjectMapper.toStatus', () {
    const mapper = GitObjectMapper();

    test('drops ignored entries', () {
      final status = mapper.toStatus(
        branchName: 'main',
        headCommit: null,
        rawStatus: {
          'tracked.dart': {libgit2.GitStatus.wtModified},
          'ignored.dart': {libgit2.GitStatus.ignored},
        },
      );

      expect(status.currentBranchName, 'main');
      expect(status.changes, hasLength(1));
      expect(status.changes.single.path, 'tracked.dart');
    });
  });

  group('FakeGitDataSource', () {
    test('returns a deterministic status', () async {
      final dataSource = FakeGitDataSource(latency: Duration.zero);
      final status = await dataSource.status(path: '/tmp/repo');

      expect(status.currentBranchName, 'main');
      expect(status.changes, isNotEmpty);
      expect(status.isClean, isFalse);
    });

    test('returns branches and commits', () async {
      final dataSource = FakeGitDataSource(latency: Duration.zero);

      final branches = await dataSource.branches(path: '/tmp/repo');
      final commits = await dataSource.log(path: '/tmp/repo', limit: 2);

      expect(branches.any((b) => b.kind == BranchKind.local), isTrue);
      expect(branches.any((b) => b.isHead), isTrue);
      expect(commits, hasLength(2));
    });

    test('paginates the log with an exclusive cursor', () async {
      final dataSource = FakeGitDataSource(latency: Duration.zero);

      final first = await dataSource.log(path: '/tmp/repo', limit: 5);
      final second = await dataSource.log(
        path: '/tmp/repo',
        limit: 5,
        from: first.last.oid,
      );

      expect(first, hasLength(5));
      expect(second, hasLength(5));
      expect(
        first
            .map((c) => c.oid.value)
            .toSet()
            .intersection(second.map((c) => c.oid.value).toSet()),
        isEmpty,
      );
    });
  });
}
