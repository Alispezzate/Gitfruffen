import 'package:equatable/equatable.dart';
import 'package:git_core/git_core.dart';

/// A repository opened in a tab, paired with the workspace snapshot loaded for
/// it: status, commit graph and refs.
class RepositoryTab extends Equatable {
  const RepositoryTab({
    required this.repository,
    required this.status,
    this.graph = const [],
    this.branches = const [],
    this.tags = const [],
    this.worktrees = const [],
    this.stashes = const [],
    this.hasMoreGraph = false,
    this.isLoadingMoreGraph = false,
  });

  final GitRepository repository;
  final RepositoryStatus status;

  /// Commits reachable from every local branch, newest first.
  final List<Commit> graph;
  final List<Branch> branches;
  final List<Tag> tags;
  final List<WorktreeInfo> worktrees;
  final List<StashEntry> stashes;

  /// Whether older commits may exist beyond [graph].
  final bool hasMoreGraph;

  /// Whether a follow-up graph page is being fetched.
  final bool isLoadingMoreGraph;

  List<Branch> get localBranches =>
      branches.where((b) => b.kind == BranchKind.local).toList();

  List<Branch> get remoteBranches =>
      branches.where((b) => b.kind == BranchKind.remote).toList();

  RepositoryTab copyWith({
    GitRepository? repository,
    RepositoryStatus? status,
    List<Commit>? graph,
    List<Branch>? branches,
    List<Tag>? tags,
    List<WorktreeInfo>? worktrees,
    List<StashEntry>? stashes,
    bool? hasMoreGraph,
    bool? isLoadingMoreGraph,
  }) => RepositoryTab(
    repository: repository ?? this.repository,
    status: status ?? this.status,
    graph: graph ?? this.graph,
    branches: branches ?? this.branches,
    tags: tags ?? this.tags,
    worktrees: worktrees ?? this.worktrees,
    stashes: stashes ?? this.stashes,
    hasMoreGraph: hasMoreGraph ?? this.hasMoreGraph,
    isLoadingMoreGraph: isLoadingMoreGraph ?? this.isLoadingMoreGraph,
  );

  @override
  List<Object?> get props => [
    repository,
    status,
    graph,
    branches,
    tags,
    worktrees,
    stashes,
    hasMoreGraph,
    isLoadingMoreGraph,
  ];
}

/// State exposed by `RepositoryBloc`.
///
/// The bloc owns every repository open in a tab plus the active one. States
/// that can hold tabs expose them through [tabs] / [active] / [activePath].
sealed class RepositoryState extends Equatable {
  const RepositoryState();

  /// Repositories currently open, in tab order.
  List<RepositoryTab> get tabs => const [];

  /// Path of the active tab, or `null` when no repository is open.
  String? get activePath => null;

  /// Whether a mutating operation is in progress for the active tab.
  bool get isBusy => false;

  /// The active tab, or `null` when no repository is open.
  RepositoryTab? get active {
    final path = activePath;
    if (path == null) {
      return null;
    }
    for (final tab in tabs) {
      if (tab.repository.path == path) {
        return tab;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [tabs, activePath, isBusy];
}

/// No repository is open yet.
final class RepositoryInitial extends RepositoryState {
  const RepositoryInitial();
}

/// An open/clone operation is in progress. Already open tabs are preserved so
/// the tab bar does not flicker while a new repository loads.
final class RepositoryLoading extends RepositoryState {
  const RepositoryLoading({
    this.tabs = const [],
    this.activePath,
    this.isBusy = false,
  });

  @override
  final List<RepositoryTab> tabs;
  @override
  final String? activePath;
  @override
  final bool isBusy;
}

/// At least one repository is open.
final class RepositoryReady extends RepositoryState {
  const RepositoryReady({
    required this.tabs,
    required this.activePath,
    this.failure,
    this.isBusy = false,
  });

  @override
  final List<RepositoryTab> tabs;
  @override
  final String activePath;

  /// Failure from an operation that did not replace the open tabs.
  ///
  /// It is transient: listeners surface it as a notification while the tabs
  /// stay usable. A failure with no tabs open becomes a [RepositoryError].
  final GitFailure? failure;

  /// Whether a mutating operation is in progress for the active tab.
  @override
  final bool isBusy;

  RepositoryReady copyWith({
    List<RepositoryTab>? tabs,
    String? activePath,
    GitFailure? failure,
    bool? isBusy,
  }) => RepositoryReady(
    tabs: tabs ?? this.tabs,
    activePath: activePath ?? this.activePath,
    failure: failure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [tabs, activePath, failure, isBusy];
}

/// An operation failed while no repository was open.
final class RepositoryError extends RepositoryState {
  const RepositoryError(this.failure);

  final GitFailure failure;

  @override
  List<Object?> get props => [failure];
}
