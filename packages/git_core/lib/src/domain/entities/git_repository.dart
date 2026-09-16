import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A Git repository opened by Gitfruffen.
@immutable
class GitRepository extends Equatable {
  const GitRepository({
    required this.path,
    required this.name,
    required this.isBare,
    required this.isHeadDetached,
    required this.isUnborn,
  });

  /// Absolute path to the working directory (or the repo itself when bare).
  final String path;
  final String name;
  final bool isBare;
  final bool isHeadDetached;
  final bool isUnborn;

  @override
  List<Object?> get props => [path, name, isBare, isHeadDetached, isUnborn];
}
