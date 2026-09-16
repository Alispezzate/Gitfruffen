import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

/// Events accepted by `SettingsBloc`.
sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

final class ThemeModeChanged extends SettingsEvent {
  const ThemeModeChanged(this.mode);

  final ThemeMode mode;
}

/// State exposed by `SettingsBloc`.
class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.recentRepositories,
    required this.engineVersion,
  });

  const SettingsState.initial()
    : themeMode = ThemeMode.system,
      recentRepositories = const [],
      engineVersion = 'unknown';

  final ThemeMode themeMode;
  final List<String> recentRepositories;
  final String engineVersion;

  SettingsState copyWith({
    ThemeMode? themeMode,
    List<String>? recentRepositories,
    String? engineVersion,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    recentRepositories: recentRepositories ?? this.recentRepositories,
    engineVersion: engineVersion ?? this.engineVersion,
  );
}

/// Global application settings: theme mode, recent repositories and version
/// information for diagnostics.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required WorkspaceRepositoryContract workspace,
    required GitDataSource dataSource,
  }) : _workspace = workspace,
       _dataSource = dataSource,
       super(const SettingsState.initial()) {
    on<SettingsLoaded>(_onLoaded);
    on<ThemeModeChanged>(_onThemeModeChanged);
  }

  final WorkspaceRepositoryContract _workspace;
  final GitDataSource _dataSource;

  void _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) {
    emit(
      state.copyWith(
        themeMode: _decodeThemeMode(_workspace.themeMode),
        recentRepositories: _workspace.recentRepositoryPaths,
        engineVersion: _engineVersion(),
      ),
    );
  }

  Future<void> _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _workspace.setThemeMode(event.mode.name);
    emit(state.copyWith(themeMode: event.mode));
  }

  ThemeMode _decodeThemeMode(String value) => switch (value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  String _engineVersion() {
    final source = _dataSource;
    return source is Libgit2GitDataSource ? source.engineVersion : 'fake';
  }
}
