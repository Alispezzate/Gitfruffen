abstract interface class GitCredentialsDataSource {
  String? get username;
  String? get passwordOrToken;

  Future<void> save({
    required String username,
    required String passwordOrToken,
  });

  Future<void> clear();
}
