import 'package:equatable/equatable.dart';
import 'package:git_core/src/domain/entities/commit.dart';
import 'package:meta/meta.dart';

/// Whether a branch lives locally or on a remote.
enum BranchKind { local, remote }

/// A named pointer to a commit.
@immutable
class Branch extends Equatable {
  const Branch({
    required this.name,
    required this.kind,
    required this.isHead,
    this.targetOid,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
  });

  final String name;
  final BranchKind kind;

  /// True when this branch is the one currently checked out.
  final bool isHead;
  final String? targetOid;

  /// Tracking branch (e.g. `origin/main`) when configured.
  final String? upstream;
  final int ahead;
  final int behind;

  bool get isRemote => kind == BranchKind.remote;

  @override
  List<Object?> get props => [
    name,
    kind,
    isHead,
    targetOid,
    upstream,
    ahead,
    behind,
  ];
}

/// A tag pointing at a commit or another object.
@immutable
class Tag extends Equatable {
  const Tag({
    required this.name,
    required this.targetOid,
    required this.isAnnotated,
    this.message,
  });

  final String name;
  final String targetOid;
  final bool isAnnotated;
  final String? message;

  @override
  List<Object?> get props => [name, targetOid, isAnnotated, message];
}

/// A summary of the working tree relative to HEAD.
@immutable
class RepositoryStatus extends Equatable {
  const RepositoryStatus({
    required this.changes,
    required this.currentBranchName,
    required this.headCommit,
  });

  final List<FileChange> changes;
  final String? currentBranchName;
  final Commit? headCommit;

  bool get isClean => changes.isEmpty;
  int get stagedCount => changes.where((c) => c.staged && !c.conflicted).length;
  int get unstagedCount =>
      changes.where((c) => c.unstaged && !c.conflicted).length;
  int get conflictedCount => changes.where((c) => c.conflicted).length;

  @override
  List<Object?> get props => [changes, currentBranchName, headCommit];
}

/// State of a single file in the working tree / index.
enum FileChangeType { added, modified, deleted, renamed, untracked, conflicted }

@immutable
class FileChange extends Equatable {
  const FileChange({
    required this.path,
    required this.type,
    required this.staged,
    required this.unstaged,
    required this.conflicted,
    this.oldPath,
  });

  final String path;
  final String? oldPath;
  final FileChangeType type;
  final bool staged;
  final bool unstaged;
  final bool conflicted;

  @override
  List<Object?> get props => [
    path,
    oldPath,
    type,
    staged,
    unstaged,
    conflicted,
  ];
}
