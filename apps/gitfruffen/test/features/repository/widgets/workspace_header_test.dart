import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/workspace_header.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

class _MockWorkspaceRepository extends Mock
    implements WorkspaceRepositoryContract {}

void main() {
  const repository = GitRepository(
    path: '/tmp/gitfruffen',
    name: 'gitfruffen',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const tab = RepositoryTab(
    repository: repository,
    status: RepositoryStatus(
      changes: [],
      currentBranchName: 'main',
      headCommit: null,
    ),
  );

  testWidgets('toggles the terminal and disables Pop without stashes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = RepositoryBloc(
      repository: _MockGitRepository(),
      workspace: _MockWorkspaceRepository(),
    );
    var terminalToggled = false;
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<RepositoryBloc>.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkspaceHeader(
              tab: tab,
              onToggleTerminal: () => terminalToggled = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('main'), findsOneWidget);

    final popButton = tester.widget<TextButton>(
      find.ancestor(of: find.text('Pop'), matching: find.byType(TextButton)),
    );
    expect(popButton.onPressed, isNull);

    await tester.tap(find.text('Terminal'));
    expect(terminalToggled, isTrue);
  });

  testWidgets('ellipsizes a long branch name without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longBranchTab = RepositoryTab(
      repository: repository,
      status: RepositoryStatus(
        changes: [],
        currentBranchName:
            'feature/this-is-a-very-long-branch-name-that-should-ellipsize-instead-of-overflowing-the-header-widget-1234567890abcdefg',
        headCommit: null,
      ),
    );

    final bloc = RepositoryBloc(
      repository: _MockGitRepository(),
      workspace: _MockWorkspaceRepository(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<RepositoryBloc>.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkspaceHeader(
              tab: longBranchTab,
              onToggleTerminal: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
