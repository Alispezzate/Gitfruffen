import 'package:file_selector/file_selector.dart';

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

/// [FilePickerService] backed by `file_selector`, which delegates to the
/// native dialog of each desktop platform.
///
/// `file_selector` has no API for a dialog window title, so the `title`
/// argument is forwarded as the confirm button label instead.
final class NativeFilePickerService implements FilePickerService {
  const NativeFilePickerService();

  @override
  Future<String?> pickDirectory({String? title}) =>
      getDirectoryPath(confirmButtonText: title);

  @override
  Future<String?> pickFile({
    String? title,
    List<String> allowedExtensions = const [],
  }) async {
    final file = await openFile(
      confirmButtonText: title,
      acceptedTypeGroups: [
        if (allowedExtensions.isNotEmpty)
          XTypeGroup(label: 'Allowed files', extensions: allowedExtensions),
      ],
    );
    return file?.path;
  }
}
