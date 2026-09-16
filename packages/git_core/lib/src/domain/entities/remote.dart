import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// A configured remote of a repository.
@immutable
class Remote extends Equatable {
  const Remote({required this.name, required this.url, this.pushUrl});

  final String name;
  final String url;
  final String? pushUrl;

  @override
  List<Object?> get props => [name, url, pushUrl];
}
