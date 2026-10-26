import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:gitfruffen/features/welcome/presentation/welcome_page.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
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

  testWidgets('offers the open, clone and new repository actions', (
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

    await tester.pumpWidget(
      BlocProvider<RepositoryBloc>.value(
        value: repositoryBloc,
        child: BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WelcomePage(),
          ),
        ),
      ),
    );

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Clone…'), findsWidgets);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Open a repository'), findsOneWidget);
    expect(find.text('Browse…'), findsOneWidget);

    await tester.tap(find.text('Clone…').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Clone a remote repository into a local folder.'),
      findsOneWidget,
    );
  });
}
