import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_core/git_core.dart';
import 'package:gitfruffen/core/di/dependency_injector.dart';
import 'package:gitfruffen/features/repository/bloc/repository_bloc.dart';
import 'package:gitfruffen/features/settings/bloc/settings_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('DependencyInjector exposes the four Pine layers', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    late BuildContext capturedContext;
    await tester.pumpWidget(
      DependencyInjector(
        preferences: preferences,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // mappers
    expect(capturedContext.read<GitObjectMapper>(), isA<GitObjectMapper>());
    // providers
    expect(capturedContext.read<GitDataSource>(), isNotNull);
    // repositories
    expect(
      capturedContext.read<GitRepositoryContract>(),
      isA<GitRepositoryContract>(),
    );
    expect(
      capturedContext.read<WorkspaceRepositoryContract>(),
      isA<WorkspaceRepositoryContract>(),
    );
    // blocs
    expect(capturedContext.read<RepositoryBloc>(), isA<RepositoryBloc>());
    expect(capturedContext.read<SettingsBloc>(), isA<SettingsBloc>());
  });
}
