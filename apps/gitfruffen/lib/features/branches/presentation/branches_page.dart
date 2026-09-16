import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../repository/bloc/repository_bloc.dart';
import '../../repository/bloc/repository_state.dart';
import '../bloc/branches_bloc.dart';
import '../bloc/branches_event.dart';
import '../bloc/branches_state.dart';

/// Local and remote branches of the open repository.
class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocListener<RepositoryBloc, RepositoryState>(
        listenWhen: (prev, next) => next is RepositoryReady,
        listener: (context, state) {
          final ready = state as RepositoryReady;
          context.read<BranchesBloc>().add(
            BranchesLoaded(path: ready.repository.path),
          );
        },
        child: BlocBuilder<BranchesBloc, BranchesState>(
          builder: (context, state) => switch (state) {
            BranchesInitial() => const AppEmptyState(
              icon: Icons.call_split_outlined,
              title: 'No branches loaded',
              message: 'Open a repository to list its branches.',
            ),
            BranchesLoading() => const AppLoading(),
            BranchesError(:final failure) => AppErrorView(
              message: failure.message,
            ),
            BranchesReady() => _BranchView(state: state),
          },
        ),
      );
}

class _BranchView extends StatelessWidget {
  const _BranchView({required this.state});

  final BranchesReady state;

  @override
  Widget build(BuildContext context) {
    final repository = context.select(
      (RepositoryBloc bloc) => bloc.state is RepositoryReady
          ? (bloc.state as RepositoryReady).repository
          : null,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _SectionHeader(title: 'Local', count: state.local.length),
        for (final branch in state.local)
          _BranchTile(
            branch: branch,
            onCheckout: repository == null
                ? null
                : () => context.read<BranchesBloc>().add(
                    BranchCheckedOut(
                      path: repository.path,
                      branch: branch.name,
                    ),
                  ),
          ),
        _SectionHeader(title: 'Remote', count: state.remote.length),
        for (final branch in state.remote) _BranchTile(branch: branch),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      '$title · $count',
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch, this.onCheckout});

  final Branch branch;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        branch.isRemote ? Icons.cloud_outlined : Icons.call_split_outlined,
        size: 18,
        color: branch.isHead ? AppColors.primary : theme.iconTheme.color,
      ),
      title: Text(
        branch.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: branch.isHead ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: branch.targetOid == null
          ? null
          : Text(branch.targetOid!, style: theme.textTheme.bodySmall),
      trailing: branch.isRemote || onCheckout == null
          ? null
          : TextButton(onPressed: onCheckout, child: const Text('Checkout')),
    );
  }
}
