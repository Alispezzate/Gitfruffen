import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:git_core/git_core.dart';
import 'package:pine/pine.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/branches/bloc/branches_bloc.dart';
import '../../features/history/bloc/history_bloc.dart';
import '../../features/repository/bloc/repository_bloc.dart';
import '../../features/settings/bloc/settings_bloc.dart';
import '../services/file_picker_service.dart';
import '../workspace/workspace_repository_impl.dart';

part 'blocs.dart';
part 'mappers.dart';
part 'providers.dart';
part 'repositories.dart';

/// Root dependency injector following the Pine architecture.
///
/// Dependencies are injected top-down in four layers:
/// `mappers` -> `providers` -> `repositories` -> `blocs`.
/// A lower layer may only depend on the layers above it, accessed through
/// `context.read()` / `context.watch()`.
class DependencyInjector extends StatelessWidget {
  const DependencyInjector({
    super.key,
    required this.preferences,
    required this.child,
  });

  /// Resolved before `runApp` and injected into the `providers` layer.
  final SharedPreferences preferences;

  final Widget child;

  @override
  Widget build(BuildContext context) => DependencyInjectorHelper(
    mappers: _mappers(),
    providers: _providers(preferences),
    repositories: _repositories(),
    blocs: _blocs(),
    child: child,
  );
}
