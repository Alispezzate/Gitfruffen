import 'package:flutter_test/flutter_test.dart';
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
  });
}
