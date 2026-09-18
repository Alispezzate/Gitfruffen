import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/core/theme/app_colors.dart';
import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/branches/bloc/branches_bloc.dart';
import 'package:gitfruffen/features/branches/bloc/branches_event.dart';
import 'package:gitfruffen/features/branches/bloc/branches_state.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Local and remote branches of the open repository.
class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final path = context.read<RepositoryBloc>().state.activePath;
      if (path != null) {
        context.read<BranchesBloc>().add(BranchesLoaded(path: path));
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<RepositoryBloc, RepositoryState>(
        listenWhen: (prev, next) =>
            next.activePath != null && prev.activePath != next.activePath,
        listener: (context, state) {
          context.read<BranchesBloc>().add(
            BranchesLoaded(path: state.activePath!),
          );
        },
        child: BlocBuilder<BranchesBloc, BranchesState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return switch (state) {
              BranchesInitial() => AppEmptyState(
                icon: Icons.call_split_outlined,
                title: l10n.emptyNoBranches,
                message: l10n.emptyNoBranchesMessage,
              ),
              BranchesLoading() => const AppLoading(),
              BranchesError(:final failure) => AppErrorView(
                message: failure.message,
              ),
              BranchesReady() => _BranchView(state: state),
            };
          },
        ),
      );
}

class _BranchView extends StatelessWidget {
  const _BranchView({required this.state});

  final BranchesReady state;

  @override
  Widget build(BuildContext context) {
    final repository = context.select<RepositoryBloc, GitRepository?>(
      (bloc) => bloc.state.active?.repository,
    );
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _SectionHeader(
          title: l10n.branchLocalSection,
          count: state.local.length,
        ),
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
        _SectionHeader(
          title: l10n.branchRemoteSection,
          count: state.remote.length,
        ),
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
      AppLocalizations.of(context).branchSectionTitle(title, count),
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
          : TextButton(
              onPressed: onCheckout,
              child: Text(AppLocalizations.of(context).checkoutButton),
            ),
    );
  }
}
