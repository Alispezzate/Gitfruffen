import 'package:equatable/equatable.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

final class HistoryLoaded extends HistoryEvent {
  const HistoryLoaded({required this.path, this.limit = 200});

  final String path;
  final int limit;

  @override
  List<Object?> get props => [path, limit];
}
