import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/core/widgets/app_shell.dart';
import 'package:gitfruffen/core/widgets/status_bar.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

class _MockWorkspaceRepository extends Mock
    implements WorkspaceRepositoryContract {}

class _MockGitDataSource extends Mock implements GitDataSource {}

void main() {
  late _MockGitRepository repository;
  late _MockWorkspaceRepository workspace;
  late _MockGitDataSource dataSource;

  setUp(() {
    repository = _MockGitRepository();
    workspace = _MockWorkspaceRepository();
    dataSource = _MockGitDataSource();
  });

  testWidgets('hosts the menu, content and status bar and navigates', (
    tester,
  ) async {
    final repositoryBloc = RepositoryBloc(
      repository: repository,
      workspace: workspace,
    );
    final settingsBloc = SettingsBloc(
      workspace: workspace,
      dataSource: dataSource,
    );
    final router = GoRouter(
      initialLocation: '/repository',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/repository',
              builder: (context, state) => const Text('repository-content'),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const Text('settings-content'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<RepositoryBloc>.value(
        value: repositoryBloc,
        child: BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('repository-content'), findsOneWidget);
    final hasMenu =
        find.byType(MenuBar).evaluate().isNotEmpty ||
        find.byType(PlatformMenuBar).evaluate().isNotEmpty;
    expect(hasMenu, isTrue);
    expect(find.byType(StatusBar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('settings-content'), findsOneWidget);
  });
}
