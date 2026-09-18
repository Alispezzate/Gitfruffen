import 'package:equatable/equatable.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class HistoryLoaded extends HistoryEvent {
  const HistoryLoaded({required this.path, this.limit = 50});

  final String path;
  final int limit;

  @override
  List<Object?> get props => [path, limit];
}

/// Requests the next page of commits for the already loaded repository.
final class HistoryLoadMore extends HistoryEvent {
  const HistoryLoadMore();
}
