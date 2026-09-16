import 'package:equatable/equatable.dart';

sealed class BranchesEvent extends Equatable {
  const BranchesEvent();

  @override
  List<Object?> get props => [];
}

final class BranchesLoaded extends BranchesEvent {
  const BranchesLoaded({required this.path});

  final String path;

  @override
  List<Object?> get props => [path];
}

final class BranchCheckedOut extends BranchesEvent {
  const BranchCheckedOut({required this.path, required this.branch});

  final String path;
  final String branch;

  @override
  List<Object?> get props => [path, branch];
}
