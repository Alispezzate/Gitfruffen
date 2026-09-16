import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import '../../../core/widgets/app_feedback.dart';
import '../../repository/bloc/repository_bloc.dart';
import '../../repository/bloc/repository_state.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';

/// Commit log for the open repository.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = context.read<RepositoryBloc>().state.activePath;
      if (path != null) {
        context.read<HistoryBloc>().add(HistoryLoaded(path: path));
      }
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<RepositoryBloc, RepositoryState>(
    listenWhen: (prev, next) =>
        next.activePath != null && prev.activePath != next.activePath,
    listener: (context, state) {
      context.read<HistoryBloc>().add(HistoryLoaded(path: state.activePath!));
    },
    child: BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) => switch (state) {
        HistoryInitial() => const AppEmptyState(
          icon: Icons.account_tree_outlined,
          title: 'No history loaded',
          message: 'Open a repository to browse its commits.',
        ),
        HistoryLoading() => const AppLoading(),
        HistoryError(:final failure) => AppErrorView(message: failure.message),
        HistoryReady(:final commits) => _CommitList(commits: commits),
      },
    ),
  );
}

class _CommitList extends StatelessWidget {
  const _CommitList({required this.commits});

  final List<Commit> commits;

  @override
  Widget build(BuildContext context) {
    if (commits.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No commits yet',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: commits.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final commit = commits[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.18),
            child: Text(
              commit.author.name.isEmpty
                  ? '?'
                  : commit.author.name.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          title: Text(commit.summary, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${commit.oid.short} · ${commit.author.name}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: commit.isMerge
              ? const Icon(Icons.merge_type, size: 16)
              : null,
        );
      },
    );
  }
}
