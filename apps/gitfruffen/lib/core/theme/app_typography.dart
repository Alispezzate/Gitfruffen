import 'package:flutter/material.dart';

import 'package:gitfruffen/core/theme/app_colors.dart';

/// Typography scale for the app shell and content areas.
abstract final class AppTypography {
  static const String _family = 'Inter';

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
    displaySmall: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodyLarge: TextStyle(fontSize: 14, color: primary),
    bodyMedium: TextStyle(fontSize: 13, color: primary),
    bodySmall: TextStyle(fontSize: 12, color: secondary),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
  );

  static TextTheme get dark =>
      textTheme(AppColors.textPrimary, AppColors.textSecondary);

  static TextTheme get light =>
      textTheme(const Color(0xFF1B1D23), const Color(0xFF5B6373));

  static const String fontFamily = _family;
}
