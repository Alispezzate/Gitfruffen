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

/// Preferred language chosen by the user.
///
/// A `null` code follows the system locale.
final class LanguageChanged extends SettingsEvent {
  const LanguageChanged(this.code);

  final String? code;
}

/// State exposed by `SettingsBloc`.
class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.languageCode,
    required this.recentRepositories,
    required this.engineVersion,
  });

  const SettingsState.initial()
    : themeMode = ThemeMode.system,
      languageCode = null,
      recentRepositories = const [],
      engineVersion = 'unknown';

  final ThemeMode themeMode;

  /// Preferred locale code (`en`, `it`) or `null` to follow the system.
  final String? languageCode;

  final List<String> recentRepositories;
  final String engineVersion;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    List<String>? recentRepositories,
    String? engineVersion,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    languageCode: languageCode ?? this.languageCode,
    recentRepositories: recentRepositories ?? this.recentRepositories,
    engineVersion: engineVersion ?? this.engineVersion,
  );

  /// Returns a copy with [languageCode] replaced, allowing `null` to restore
  /// the system locale.
  SettingsState withLanguageCode(String? languageCode) => SettingsState(
    themeMode: themeMode,
    languageCode: languageCode,
    recentRepositories: recentRepositories,
    engineVersion: engineVersion,
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
    on<LanguageChanged>(_onLanguageChanged);
  }

  final WorkspaceRepositoryContract _workspace;
  final GitDataSource _dataSource;

  void _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) {
    emit(
      state.copyWith(
        themeMode: _decodeThemeMode(_workspace.themeMode),
        languageCode: _decodeLanguageCode(_workspace.languageCode),
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

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _workspace.setLanguageCode(event.code ?? 'system');
    emit(state.withLanguageCode(event.code));
  }

  ThemeMode _decodeThemeMode(String value) => switch (value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  String? _decodeLanguageCode(String value) => switch (value) {
    'system' => null,
    final code => code,
  };

  String _engineVersion() {
    final source = _dataSource;
    return source is Libgit2GitDataSource ? source.engineVersion : 'fake';
  }
}
