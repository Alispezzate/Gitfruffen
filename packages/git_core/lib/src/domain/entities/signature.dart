import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Author / committer identity attached to a Git object.
@immutable
class Signature extends Equatable {
  const Signature({
    required this.name,
    required this.email,
    required this.when,
  });

  final String name;
  final String email;
  final DateTime when;

  @override
  List<Object?> get props => [name, email, when];
}
