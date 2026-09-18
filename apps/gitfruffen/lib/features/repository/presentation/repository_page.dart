import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gitfruffen/core/widgets/app_feedback.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/repository/bloc/repository_event.dart';
import 'package:gitfruffen/features/repository/bloc/repository_state.dart';
import 'package:gitfruffen/features/repository/presentation/graph/commit_graph_view.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/changes_panel.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/repository_refs_panel.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/repository_toolbar.dart';
import 'package:gitfruffen/features/repository/presentation/widgets/resize_handle.dart';
import 'package:gitfruffen/l10n/generated/app_localizations.dart';

/// Three-pane repository workspace.
///
/// A toolbar sits on top; below it the left panel lists refs, the centre shows
/// the commit graph and the right panel shows changes plus the commit prompt.
class RepositoryPage extends StatelessWidget {
  const RepositoryPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RepositoryBloc, RepositoryState>(
    buildWhen: (previous, next) =>
        previous.active != next.active ||
        previous.runtimeType != next.runtimeType ||
        previous.isBusy != next.isBusy,
    builder: (context, state) {
      final active = state.active;
      final l10n = AppLocalizations.of(context);
      if (active == null) {
        return switch (state) {
          RepositoryInitial() => AppEmptyState(
            icon: Icons.folder_off_outlined,
            title: l10n.emptyNoRepository,
            message: l10n.emptyNoRepositoryMessage,
          ),
          RepositoryLoading() => AppLoading(message: l10n.openingRepository),
          RepositoryError(:final failure) => AppErrorView(
            message: failure.message,
            onRetry: () =>
                context.read<RepositoryBloc>().add(const RepositoryRefreshed()),
          ),
          RepositoryReady() => AppEmptyState(
            icon: Icons.folder_off_outlined,
            title: l10n.emptyNoRepository,
          ),
        };
      }
      return _Workspace(tab: active);
    },
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace({required this.tab});

  final RepositoryTab tab;

  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  static const double _minPane = 180;
  static const double _maxPane = 520;

  double _leftWidth = 260;
  double _rightWidth = 340;

  void _resizeLeft(double delta) {
    setState(() {
      _leftWidth = (_leftWidth + delta).clamp(_minPane, _maxPane);
    });
  }

  void _resizeRight(double delta) {
    setState(() {
      _rightWidth = (_rightWidth - delta).clamp(_minPane, _maxPane);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        RepositoryToolbar(tab: widget.tab),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: _leftWidth,
                child: RepositoryRefsPanel(tab: widget.tab),
              ),
              ResizeHandle(onDragged: _resizeLeft),
              Expanded(
                child: ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: CommitGraphView(tab: widget.tab),
                ),
              ),
              ResizeHandle(onDragged: _resizeRight),
              Container(
                width: _rightWidth,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(left: BorderSide(color: theme.dividerColor)),
                ),
                child: ChangesPanel(tab: widget.tab),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
