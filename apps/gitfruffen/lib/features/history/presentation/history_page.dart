import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/history/bloc/history_bloc.dart';
import 'package:gitfruffen/features/history/bloc/history_event.dart';
import 'package:gitfruffen/features/history/bloc/history_state.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

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
      if (!mounted) {
        return;
      }
      final path = context.read<RepositoryBloc>().state.activePath;
      if (path != null) {
        context.read<HistoryBloc>().add(HistoryLoaded(path: path));
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<RepositoryBloc, RepositoryState>(
        listenWhen: (prev, next) =>
            next.activePath != null && prev.activePath != next.activePath,
        listener: (context, state) {
          context.read<HistoryBloc>().add(
            HistoryLoaded(path: state.activePath!),
          );
        },
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return switch (state) {
              HistoryInitial() => AppEmptyState(
                icon: Icons.account_tree_outlined,
                title: l10n.emptyNoHistory,
                message: l10n.emptyNoHistoryMessage,
              ),
              HistoryLoading() => const AppLoading(),
              HistoryError(:final failure) => AppErrorView(
                message: failure.message,
              ),
              HistoryReady() => _CommitList(state: state),
            };
          },
        ),
      );
}

/// Paginated commit list.
///
/// It appends the next page when the user scrolls near the bottom and also
/// auto-fills the first pages while the content does not cover the viewport,
/// so short repositories keep loading until their history is fully shown.
class _CommitList extends StatefulWidget {
  const _CommitList({required this.state});

  final HistoryReady state;

  @override
  State<_CommitList> createState() => _CommitListState();
}

class _CommitListState extends State<_CommitList> {
  static const _threshold = 400.0;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoFill());
  }

  @override
  void didUpdateWidget(_CommitList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state.commits, widget.state.commits)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoFill());
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _threshold) {
      _loadMore();
    }
  }

  void _autoFill() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    if (position.maxScrollExtent <= 0 ||
        position.viewportDimension >= position.maxScrollExtent) {
      _loadMore();
    }
  }

  void _loadMore() {
    final state = widget.state;
    if (!state.hasMore || state.isLoadingMore) {
      return;
    }
    context.read<HistoryBloc>().add(const HistoryLoadMore());
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final commits = state.commits;
    final l10n = AppLocalizations.of(context);
    if (commits.isEmpty) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: l10n.emptyNoCommits,
      );
    }

    final showFooter = state.hasMore || state.isLoadingMore;
    return ListView.separated(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: commits.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= commits.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: AppLoading(),
          );
        }
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
            l10n.commitSubtitle(commit.oid.short, commit.author.name),
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
