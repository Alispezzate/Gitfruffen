import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_event.dart';
import 'package:gitfruffen/features/repository/bloc/file_diff_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

void main() {
  late _MockGitRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const GitOid('0000000000000000000000000000000000000000'),
    );
  });

  setUp(() => repository = _MockGitRepository());

  const path = '/tmp/gitfruffen-a';
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
  const updatedFile = DiffFile(
    path: 'lib/a.dart',
    changeType: FileChangeType.modified,
    isBinary: false,
    insertions: 3,
    deletions: 0,
  );
  const request = OpenFileRequest(
    repositoryPath: path,
    file: file,
    source: FileDiffSource.unstaged,
  );

  FileDiffState initialState() => const FileDiffState(
    repositoryPath: path,
    source: FileDiffSource.unstaged,
    file: file,
  );

  FileDiffBloc build() =>
      FileDiffBloc(repository: repository, request: request);

  final signature = Signature(
    name: 'Ada Lovelace',
    email: 'ada@gitfruffen.dev',
    when: DateTime.utc(2026),
  );
  final commit = Commit(
    oid: GitOid('c' * 40),
    message: 'fix things\n',
    summary: 'fix things',
    author: signature,
    committer: signature,
    parentOids: const [],
  );
  final blame = [
    BlameLine(
      line: 1,
      commitOid: commit.oid,
      summary: commit.summary,
      author: signature,
      isBoundary: true,
    ),
  ];

  test('initial state mirrors the request', () async {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state, initialState());
  });

  blocTest<FileDiffBloc, FileDiffState>(
    'toggling whitespace re-diffs the working tree and updates the file',
    setUp: () {
      when(
        () => repository.diffWorkingTree(
          path: path,
          staged: false,
          ignoreWhitespace: true,
          contextLines: any(named: 'contextLines'),
        ),
      ).thenAnswer((_) async => const DiffResult(files: [updatedFile]));
    },
    build: build,
    act: (bloc) => bloc.add(const FileDiffWhitespaceToggled(true)),
    expect: () => [
      initialState().copyWith(
        ignoreWhitespace: true,
        isLoadingDiff: true,
        clearFailure: true,
      ),
      initialState().copyWith(ignoreWhitespace: true, file: updatedFile),
    ],
    verify: (_) {
      verify(
        () => repository.diffWorkingTree(
          path: path,
          staged: false,
          ignoreWhitespace: true,
          contextLines: any(named: 'contextLines'),
        ),
      ).called(1);
    },
  );

  blocTest<FileDiffBloc, FileDiffState>(
    'enabling full file re-diffs with a large context and sets fullFile',
    setUp: () {
      when(
        () => repository.diffWorkingTree(
          path: path,
          staged: false,
          contextLines: any(named: 'contextLines'),
        ),
      ).thenAnswer((_) async => const DiffResult(files: [updatedFile]));
    },
    build: build,
    act: (bloc) => bloc.add(const FileDiffFullFileToggled(true)),
    expect: () => [
      initialState().copyWith(
        fullFile: true,
        isLoadingDiff: true,
        clearFailure: true,
      ),
      initialState().copyWith(fullFile: true, file: updatedFile),
    ],
    verify: (_) {
      final context =
          verify(
                () => repository.diffWorkingTree(
                  path: path,
                  staged: false,
                  contextLines: captureAny(named: 'contextLines'),
                ),
              ).captured.single
              as int;
      expect(context, greaterThan(3));
    },
  );

  blocTest<FileDiffBloc, FileDiffState>(
    'disabling full file re-diffs with the default context',
    setUp: () {
      when(
        () => repository.diffWorkingTree(
          path: path,
          staged: false,
          contextLines: any(named: 'contextLines'),
        ),
      ).thenAnswer((_) async => const DiffResult(files: [file]));
    },
    build: build,
    seed: () => initialState().copyWith(fullFile: true),
    act: (bloc) => bloc.add(const FileDiffFullFileToggled(false)),
    expect: () => [
      initialState().copyWith(
        fullFile: false,
        isLoadingDiff: true,
        clearFailure: true,
      ),
      initialState().copyWith(fullFile: false, file: file),
    ],
    verify: (_) {
      final context =
          verify(
                () => repository.diffWorkingTree(
                  path: path,
                  staged: false,
                  contextLines: captureAny(named: 'contextLines'),
                ),
              ).captured.single
              as int;
      expect(context, 3);
    },
  );

  blocTest<FileDiffBloc, FileDiffState>(
    'whitespace toggle preserves the full file context',
    setUp: () {
      when(
        () => repository.diffWorkingTree(
          path: path,
          staged: false,
          ignoreWhitespace: true,
          contextLines: any(named: 'contextLines'),
        ),
      ).thenAnswer((_) async => const DiffResult(files: [updatedFile]));
    },
    build: build,
    seed: () => initialState().copyWith(fullFile: true),
    act: (bloc) => bloc.add(const FileDiffWhitespaceToggled(true)),
    expect: () => [
      initialState().copyWith(
        fullFile: true,
        ignoreWhitespace: true,
        isLoadingDiff: true,
        clearFailure: true,
      ),
      initialState().copyWith(
        fullFile: true,
        ignoreWhitespace: true,
        file: updatedFile,
      ),
    ],
    verify: (_) {
      final context =
          verify(
                () => repository.diffWorkingTree(
                  path: path,
                  staged: false,
                  ignoreWhitespace: true,
                  contextLines: captureAny(named: 'contextLines'),
                ),
              ).captured.single
              as int;
      expect(context, greaterThan(3));
    },
  );

  blocTest<FileDiffBloc, FileDiffState>(
    'blame request emits loading then the lines',
    setUp: () {
      when(
        () => repository.blameFile(
          path: path,
          filePath: file.path,
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async => blame);
    },
    build: build,
    act: (bloc) => bloc.add(const FileDiffBlameRequested()),
    expect: () => [
      initialState().copyWith(isLoadingBlame: true, clearFailure: true),
      initialState().copyWith(blame: blame),
    ],
    verify: (_) {
      verify(
        () => repository.blameFile(
          path: path,
          filePath: file.path,
          at: any(named: 'at'),
        ),
      ).called(1);
    },
  );

  blocTest<FileDiffBloc, FileDiffState>(
    'history is loaded once and reused',
    setUp: () {
      when(
        () => repository.fileHistory(path: path, filePath: file.path),
      ).thenAnswer((_) async => [commit]);
    },
    build: build,
    act: (bloc) async {
      bloc.add(const FileDiffHistoryRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FileDiffHistoryRequested());
    },
    expect: () => [
      initialState().copyWith(isLoadingHistory: true, clearFailure: true),
      initialState().copyWith(history: [commit]),
    ],
    verify: (_) {
      verify(
        () => repository.fileHistory(path: path, filePath: file.path),
      ).called(1);
    },
  );

  blocTest<FileDiffBloc, FileDiffState>(
    'selecting a history commit switches source, oid and clears blame',
    setUp: () {
      when(
        () => repository.diffCommit(
          path: path,
          oid: commit.oid,
          ignoreWhitespace: any(named: 'ignoreWhitespace'),
          contextLines: any(named: 'contextLines'),
        ),
      ).thenAnswer((_) async => const DiffResult(files: [updatedFile]));
    },
    build: build,
    seed: () => initialState().copyWith(blame: blame),
    act: (bloc) => bloc.add(FileDiffHistoryCommitSelected(commit.oid)),
    expect: () => [
      initialState().copyWith(
        blame: blame,
        isLoadingDiff: true,
        clearFailure: true,
      ),
      initialState().copyWith(
        file: updatedFile,
        source: FileDiffSource.commit,
        commitOid: commit.oid,
      ),
    ],
  );
}
