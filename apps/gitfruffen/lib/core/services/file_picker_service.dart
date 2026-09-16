/// Selects files and directories from the host operating system.
///
/// The concrete implementation is platform specific; the contract keeps the
/// blocs free of desktop plugin details and easy to fake in tests.
abstract interface class FilePickerService {
  /// Opens a native directory picker and returns the chosen absolute path.
  Future<String?> pickDirectory({String? title});

  /// Opens a native file picker for a single file.
  Future<String?> pickFile({
    String? title,
    List<String> allowedExtensions = const [],
  });
}

/// Default implementation backed by the host file system.
///
/// Wiring to a native picker plugin lands in the next milestone; until then it
/// resolves immediately with no selection so the UI remains usable.
final class NativeFilePickerService implements FilePickerService {
  const NativeFilePickerService();

  @override
  Future<String?> pickDirectory({String? title}) async => null;

  @override
  Future<String?> pickFile({
    String? title,
    List<String> allowedExtensions = const [],
  }) async => null;
}
