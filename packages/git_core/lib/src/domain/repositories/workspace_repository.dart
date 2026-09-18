import 'package:git_core/src/domain/entities/git_repository.dart';

/// Contract for recent repositories and global workspace settings.
abstract interface class WorkspaceRepositoryContract {
  /// Paths of the most recently opened repositories, newest first.
  List<String> get recentRepositoryPaths;

  Future<void> rememberRecentRepository(GitRepository repository);

  Future<void> clearRecentRepositories();

  /// Identifier of the active theme (e.g. `system`, `dark`, `light`).
  String get themeMode;

  Future<void> setThemeMode(String value);

  /// Identifier of the preferred language (e.g. `system`, `en`, `it`).
  String get languageCode;

  Future<void> setLanguageCode(String value);
}
