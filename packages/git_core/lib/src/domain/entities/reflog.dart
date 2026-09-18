import 'package:equatable/equatable.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/signature.dart';
import 'package:meta/meta.dart';

/// A single entry of a reference log (reflog).
///
/// Used by the UI to navigate history back and forth, since Git has no native
/// undo/redo stack.
@immutable
class ReflogEntry extends Equatable {
  const ReflogEntry({
    required this.oldOid,
    required this.newOid,
    required this.message,
    required this.committer,
  });

  /// Where the reference pointed before the recorded change.
  final GitOid oldOid;

  /// Where the reference pointed after the recorded change.
  final GitOid newOid;
  final String message;
  final Signature committer;

  @override
  List<Object?> get props => [oldOid, newOid, message, committer];
}
