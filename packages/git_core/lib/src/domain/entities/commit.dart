import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'git_oid.dart';
import 'signature.dart';

/// A single commit in the repository graph.
@immutable
class Commit extends Equatable {
  const Commit({
    required this.oid,
    required this.message,
    required this.summary,
    required this.author,
    required this.committer,
    required this.parentOids,
  });

  final GitOid oid;
  final String message;

  /// First line of [message].
  final String summary;
  final Signature author;
  final Signature committer;
  final List<GitOid> parentOids;

  bool get isMerge => parentOids.length > 1;

  @override
  List<Object?> get props => [
    oid,
    message,
    summary,
    author,
    committer,
    parentOids,
  ];
}
