import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/core/services/file_picker_service.dart';
import 'package:gitfruffen/core/widgets/repository_tabs.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

class _MockWorkspaceRepository extends Mock
    implements WorkspaceRepositoryContract {}

class _MockFilePickerService extends Mock implements FilePickerService {}

void main() {
  late _MockGitRepository repository;
  late _MockWorkspaceRepository workspace;
  late _MockFilePickerService picker;

  const pathA = '/tmp/gitfruffen-a';
  const pathB = '/tmp/gitfruffen-b';
  const repoA = GitRepository(
    path: pathA,
    name: 'alpha',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const repoB = GitRepository(
    path: pathB,
    name: 'beta',
    isBare: false,
    isHeadDetached: false,
    isUnborn: false,
  );
  const status = RepositoryStatus(
    changes: [],
    currentBranchName: 'main',
    headCommit: null,
  );

  setUpAll(() {
    registerFallbackValue(
      const GitRepository(
        path: '',
        name: '',
        isBare: false,
        isHeadDetached: false,
        isUnborn: false,
      ),
    );
  });

  setUp(() {
    repository = _MockGitRepository();
    workspace = _MockWorkspaceRepository();
    picker = _MockFilePickerService();
    when(
      () => workspace.rememberRecentRepository(any()),
    ).thenAnswer((_) async {});
    when(
      () => repository.status(path: any(named: 'path')),
    ).thenAnswer((_) async => status);
    when(
      () => repository.dispose(path: any(named: 'path')),
    ).thenAnswer((_) async {});
    when(
      () => repository.discover(startPath: any(named: 'startPath')),
    ).thenAnswer(
      (invocation) async =>
          invocation.namedArguments[#startPath] == pathB ? repoB : repoA,
    );
  });

  Future<void> pumpTabs(
    WidgetTester tester, {
    required RepositoryState state,
  }) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [RepositoryProvider<FilePickerService>.value(value: picker)],
        child: BlocProvider<RepositoryBloc>(
          create: (_) =>
              RepositoryBloc(repository: repository, workspace: workspace),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocBuilder<RepositoryBloc, RepositoryState>(
              builder: (context, _) => const Scaffold(body: RepositoryTabs()),
            ),
          ),
        ),
      ),
    );

    final bloc = tester
        .element(find.byType(RepositoryTabs))
        .read<RepositoryBloc>();
    if (state is RepositoryReady) {
      for (final tab in state.tabs) {
        bloc.add(RepositoryOpened(tab.repository.path));
        await tester.pumpAndSettle();
      }
    }
    await tester.pump();
  }

  testWidgets('renders nothing when no repository is open', (tester) async {
    await pumpTabs(tester, state: const RepositoryInitial());

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('alpha'), findsNothing);
  });

  testWidgets('shows one tab per open repository and marks the active one', (
    tester,
  ) async {
    await pumpTabs(
      tester,
      state: const RepositoryReady(
        tabs: [
          RepositoryTab(repository: repoA, status: status),
          RepositoryTab(repository: repoB, status: status),
        ],
        activePath: pathB,
      ),
    );

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);

    final beta = tester.widget<Text>(find.text('beta'));
    expect(beta.style?.fontWeight, FontWeight.w600);
    final alpha = tester.widget<Text>(find.text('alpha'));
    expect(alpha.style?.fontWeight, FontWeight.w400);
  });

  testWidgets('tapping a tab selects that repository', (tester) async {
    await pumpTabs(
      tester,
      state: const RepositoryReady(
        tabs: [
          RepositoryTab(repository: repoA, status: status),
          RepositoryTab(repository: repoB, status: status),
        ],
        activePath: pathB,
      ),
    );

    await tester.tap(find.text('alpha'));
    await tester.pumpAndSettle();

    final bloc = tester
        .element(find.byType(RepositoryTabs))
        .read<RepositoryBloc>();
    expect(bloc.state.activePath, pathA);
  });

  testWidgets('the close button removes its tab', (tester) async {
    await pumpTabs(
      tester,
      state: const RepositoryReady(
        tabs: [
          RepositoryTab(repository: repoA, status: status),
          RepositoryTab(repository: repoB, status: status),
        ],
        activePath: pathB,
      ),
    );

    expect(find.byIcon(Icons.close), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('alpha'), findsNothing);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('the Open button browses and opens the picked folder', (
    tester,
  ) async {
    when(
      () => picker.pickDirectory(title: any(named: 'title')),
    ).thenAnswer((_) async => pathB);

    await pumpTabs(
      tester,
      state: const RepositoryReady(
        tabs: [RepositoryTab(repository: repoA, status: status)],
        activePath: pathA,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final bloc = tester
        .element(find.byType(RepositoryTabs))
        .read<RepositoryBloc>();
    expect(bloc.state.tabs, hasLength(2));
    expect(bloc.state.activePath, pathB);
  });
}
