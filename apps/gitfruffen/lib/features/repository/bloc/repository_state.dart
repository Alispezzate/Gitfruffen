import 'package:equatable/equatable.dart';
import 'package:git_core/git_core.dart';

/// A repository opened in a tab, paired with its last loaded status.
class RepositoryTab extends Equatable {
  const RepositoryTab({required this.repository, required this.status});

  final GitRepository repository;
  final RepositoryStatus status;

  @override
  List<Object?> get props => [repository, status];
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
  List<Object?> get props => [tabs, activePath];
}

/// No repository is open yet.
final class RepositoryInitial extends RepositoryState {
  const RepositoryInitial();
}

/// An open/clone operation is in progress. Already open tabs are preserved so
/// the tab bar does not flicker while a new repository loads.
final class RepositoryLoading extends RepositoryState {
  const RepositoryLoading({this.tabs = const [], this.activePath});

  @override
  final List<RepositoryTab> tabs;
  @override
  final String? activePath;
}

/// At least one repository is open.
final class RepositoryReady extends RepositoryState {
  const RepositoryReady({
    required this.tabs,
    required this.activePath,
    this.failure,
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

  @override
  List<Object?> get props => [tabs, activePath, failure];
}

/// An operation failed while no repository was open.
final class RepositoryError extends RepositoryState {
  const RepositoryError(this.failure);

  final GitFailure failure;

  @override
  List<Object?> get props => [failure];
}
