import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/features/history/bloc/history_bloc.dart';
import 'package:gitfruffen/features/history/bloc/history_event.dart';
import 'package:gitfruffen/features/history/bloc/history_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGitRepository extends Mock implements GitRepositoryContract {}

void main() {
  late _MockGitRepository repository;

  const path = '/tmp/gitfruffen';

  Commit commit(String sha) => Commit(
    oid: GitOid(sha),
    message: 'subject\n',
    summary: 'subject',
    author: Signature(
      name: 'Ada Lovelace',
      email: 'ada@gitfruffen.dev',
      when: DateTime.utc(2026),
    ),
    committer: Signature(
      name: 'Ada Lovelace',
      email: 'ada@gitfruffen.dev',
      when: DateTime.utc(2026),
    ),
    parentOids: const [],
  );

  final page = List.generate(50, (i) => commit('${i + 1}'.padLeft(40, '0')));

  setUp(() => repository = _MockGitRepository());

  HistoryBloc build() => HistoryBloc(repository: repository);

  blocTest<HistoryBloc, HistoryState>(
    'loads the first page and flags more available on a full page',
    setUp: () {
      when(
        () => repository.log(
          path: path,
          limit: 50,
          from: any(named: 'from'),
        ),
      ).thenAnswer((_) async => page);
    },
    build: build,
    act: (bloc) => bloc.add(const HistoryLoaded(path: path)),
    expect: () => [
      const HistoryLoading(),
      HistoryReady(page, path: path, hasMore: true),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'flags no more when the first page is not full',
    setUp: () {
      when(
        () => repository.log(
          path: path,
          limit: 50,
          from: any(named: 'from'),
        ),
      ).thenAnswer((_) async => page.take(10).toList());
    },
    build: build,
    act: (bloc) => bloc.add(const HistoryLoaded(path: path)),
    expect: () => [
      const HistoryLoading(),
      HistoryReady(page.take(10).toList(), path: path),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'appends the next page using the last commit as exclusive cursor',
    setUp: () {
      when(
        () => repository.log(path: path, limit: 50, from: page.last.oid),
      ).thenAnswer((_) async => page.take(5).toList());
    },
    build: build,
    seed: () => HistoryReady(page, path: path, hasMore: true),
    act: (bloc) => bloc.add(const HistoryLoadMore()),
    expect: () => [
      HistoryReady(page, path: path, hasMore: true, isLoadingMore: true),
      HistoryReady([...page, ...page.take(5)], path: path),
    ],
    verify: (_) {
      verify(
        () => repository.log(path: path, limit: 50, from: page.last.oid),
      ).called(1);
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'does not load more when the history is exhausted',
    build: build,
    seed: () => HistoryReady(page.take(10).toList(), path: path),
    act: (bloc) => bloc.add(const HistoryLoadMore()),
    expect: () => const <HistoryState>[],
  );

  blocTest<HistoryBloc, HistoryState>(
    'ignores load more before any repository is loaded',
    build: build,
    act: (bloc) => bloc.add(const HistoryLoadMore()),
    expect: () => const <HistoryState>[],
  );

  blocTest<HistoryBloc, HistoryState>(
    'a failing follow-up page surfaces the error',
    setUp: () {
      when(
        () => repository.log(path: path, limit: 50, from: page.last.oid),
      ).thenThrow(const RepositoryNotFoundFailure('boom'));
    },
    build: build,
    seed: () => HistoryReady(page, path: path, hasMore: true),
    act: (bloc) => bloc.add(const HistoryLoadMore()),
    expect: () => [
      HistoryReady(page, path: path, hasMore: true, isLoadingMore: true),
      const HistoryError(RepositoryNotFoundFailure('boom')),
    ],
  );
}
