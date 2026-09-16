import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData] used across Gitfruffen.
abstract final class AppTheme {
  static const double radius = 8;
  static const double sidebarWidth = 260;

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    surface: AppColors.surface,
    elevated: AppColors.surfaceElevated,
    border: AppColors.border,
    textTheme: AppTypography.dark,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    surface: AppColors.surfaceLight,
    elevated: AppColors.surfaceElevatedLight,
    border: AppColors.borderLight,
    textTheme: AppTypography.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color elevated,
    required Color border,
    required TextTheme textTheme,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: surface,
          outline: border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      dividerColor: border,
      cardTheme: CardThemeData(
        color: elevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
      iconTheme: IconThemeData(color: textTheme.bodySmall?.color, size: 18),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
  }
}
