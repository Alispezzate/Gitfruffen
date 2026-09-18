import 'package:git_core/git_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [WorkspaceRepositoryContract] backed by `shared_preferences`.
///
/// Recent repositories and the theme mode are small, non-relational values, so
/// a key/value store is sufficient for this milestone. The contract stays stable
/// if we later migrate to `drift`.
final class WorkspaceRepositoryImpl implements WorkspaceRepositoryContract {
  WorkspaceRepositoryImpl({required SharedPreferences preferences})
    : _preferences = preferences;

  static const _recentKey = 'workspace.recent_repositories';
  static const _themeKey = 'workspace.theme_mode';
  static const _languageKey = 'workspace.language_code';
  static const _maxRecent = 15;

  final SharedPreferences _preferences;

  @override
  List<String> get recentRepositoryPaths =>
      _preferences.getStringList(_recentKey) ?? const [];

  @override
  Future<void> rememberRecentRepository(GitRepository repository) async {
    final updated = [
      repository.path,
      ...recentRepositoryPaths.where((p) => p != repository.path),
    ].take(_maxRecent).toList();
    await _preferences.setStringList(_recentKey, updated);
  }

  @override
  Future<void> clearRecentRepositories() => _preferences.remove(_recentKey);

  @override
  String get themeMode => _preferences.getString(_themeKey) ?? 'system';

  @override
  Future<void> setThemeMode(String value) =>
      _preferences.setString(_themeKey, value);

  @override
  String get languageCode => _preferences.getString(_languageKey) ?? 'system';

  @override
  Future<void> setLanguageCode(String value) =>
      _preferences.setString(_languageKey, value);
}
