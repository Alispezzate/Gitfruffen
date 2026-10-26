import 'package:equatable/equatable.dart';
import 'package:git_core/src/domain/entities/branch.dart';
import 'package:meta/meta.dart';

/// Kind of a single line inside a diff hunk.
enum DiffLineKind { context, added, removed }

/// A single line of a diff hunk.
@immutable
class DiffLine extends Equatable {
  const DiffLine({
    required this.kind,
    required this.content,
    this.oldLine,
    this.newLine,
  });

  final DiffLineKind kind;

  /// Line content without its trailing newline; other whitespace is preserved.
  final String content;

  /// Line number in the old file, `null` for added lines.
  final int? oldLine;

  /// Line number in the new file, `null` for removed lines.
  final int? newLine;

  @override
  List<Object?> get props => [kind, content, oldLine, newLine];
}

/// A contiguous changed section of a single file.
@immutable
class DiffHunk extends Equatable {
  const DiffHunk({required this.header, required this.lines});

  /// Hunk header without the trailing newline, e.g. `@@ -1,4 +1,4 @@`.
  final String header;

  final List<DiffLine> lines;

  @override
  List<Object?> get props => [header, lines];
}

/// The diff of a single file.
@immutable
class DiffFile extends Equatable {
  const DiffFile({
    required this.path,
    required this.changeType,
    required this.isBinary,
    required this.insertions,
    required this.deletions,
    this.oldPath,
    this.hunks = const [],
  });

  final String path;

  /// Previous path, set only when the file was renamed or copied.
  final String? oldPath;

  final FileChangeType changeType;
  final bool isBinary;
  final int insertions;
  final int deletions;
  final List<DiffHunk> hunks;

  @override
  List<Object?> get props => [
    path,
    oldPath,
    changeType,
    isBinary,
    insertions,
    deletions,
    hunks,
  ];
}

/// The complete diff of a commit or of the working tree.
@immutable
class DiffResult extends Equatable {
  const DiffResult({required this.files});

  final List<DiffFile> files;

  int get insertions => files.fold(0, (sum, file) => sum + file.insertions);

  int get deletions => files.fold(0, (sum, file) => sum + file.deletions);

  bool get isEmpty => files.isEmpty;

  @override
  List<Object?> get props => [files];
}
