import 'package:equatable/equatable.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:meta/meta.dart';

/// A single entry in the repository stash list.
@immutable
class StashEntry extends Equatable {
  const StashEntry({
    required this.index,
    required this.message,
    required this.oid,
  });

  /// Position in the stash list, where `0` is the most recent entry.
  final int index;
  final String message;
  final GitOid oid;

  @override
  List<Object?> get props => [index, message, oid];
}
