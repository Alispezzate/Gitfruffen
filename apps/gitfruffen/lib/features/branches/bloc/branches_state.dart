import 'package:equatable/equatable.dart';
import 'package:git_core/git_core.dart';

sealed class BranchesState extends Equatable {
  const BranchesState();

  @override
  List<Object?> get props => [];
}

final class BranchesInitial extends BranchesState {
  const BranchesInitial();
}

final class BranchesLoading extends BranchesState {
  const BranchesLoading();
}

final class BranchesReady extends BranchesState {
  const BranchesReady(this.branches);

  final List<Branch> branches;

  List<Branch> get local =>
      branches.where((b) => b.kind == BranchKind.local).toList();

  List<Branch> get remote =>
      branches.where((b) => b.kind == BranchKind.remote).toList();

  @override
  List<Object?> get props => [branches];
}

final class BranchesError extends BranchesState {
  const BranchesError(this.failure);

  final GitFailure failure;

  @override
  List<Object?> get props => [failure];
}
