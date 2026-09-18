import 'package:meta/meta.dart';

/// How a reset affects HEAD, the index and the working tree.
@immutable
enum GitResetMode {
  /// Moves HEAD only.
  soft,

  /// Moves HEAD and resets the index.
  mixed,

  /// Moves HEAD and discards index and working tree changes.
  hard,
}
