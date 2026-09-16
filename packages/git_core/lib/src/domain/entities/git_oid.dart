import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Immutable identifier of a Git object (SHA-1 hex string).
@immutable
class GitOid extends Equatable {
  const GitOid(this.value)
    : assert(value.length >= 4 && value.length <= 40, 'Invalid SHA length');

  final String value;

  /// Abbreviated form used across the UI (first 7 characters).
  String get short => value.length <= 7 ? value : value.substring(0, 7);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
