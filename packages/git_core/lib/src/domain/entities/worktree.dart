import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A linked working tree attached to a repository.
@immutable
class WorktreeInfo extends Equatable {
  const WorktreeInfo({
    required this.name,
    required this.path,
    this.branch,
    this.isLocked = false,
    this.isPrunable = false,
    this.isMain = false,
  });

  final String name;
  final String path;

  /// Branch checked out in the linked worktree, when known.
  final String? branch;
  final bool isLocked;
  final bool isPrunable;

  /// True for the repository's principal working tree.
  final bool isMain;

  @override
  List<Object?> get props => [name, path, branch, isLocked, isPrunable, isMain];
}
