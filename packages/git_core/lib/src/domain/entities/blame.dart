import 'package:equatable/equatable.dart';
import 'package:git_core/src/domain/entities/git_oid.dart';
import 'package:git_core/src/domain/entities/signature.dart';
import 'package:meta/meta.dart';

/// A single line of a file together with the commit that last changed it.
@immutable
class BlameLine extends Equatable {
  const BlameLine({
    required this.line,
    required this.commitOid,
    required this.summary,
    required this.author,
    required this.isBoundary,
  });

  /// 1-based line number in the blamed (new) file.
  final int line;

  final GitOid commitOid;

  final String summary;

  final Signature author;

  /// Whether the commit is a boundary of the blame walk.
  final bool isBoundary;

  @override
  List<Object?> get props => [line, commitOid, summary, author, isBoundary];
}
