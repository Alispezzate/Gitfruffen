import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/file_diff_view.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

void main() {
  const file = DiffFile(
    path: 'lib/a.dart',
    changeType: FileChangeType.modified,
    isBinary: false,
    insertions: 1,
    deletions: 1,
    hunks: [
      DiffHunk(
        header: '@@ -1 +1 @@',
        lines: [
          DiffLine(kind: DiffLineKind.removed, content: 'old line', oldLine: 1),
          DiffLine(kind: DiffLineKind.added, content: 'new line', newLine: 1),
        ],
      ),
    ],
  );

  testWidgets('renders added and removed lines with markers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: FileDiffView(file: file, onBack: () {}),
          ),
        ),
      ),
    );

    expect(find.text('old line'), findsOneWidget);
    expect(find.text('new line'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('-'), findsWidgets);
  });
}
