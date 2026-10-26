import 'package:flutter/material.dart';

/// Centralised colour palette for Gitfruffen.
///
/// A neutral desktop palette built on GitHub dark surfaces:
/// restrained chrome, a blue primary accent and semantic colours for Git
/// states.
abstract final class AppColors {
  // Surfaces (dark)
  static const Color surface = Color(0xFF17181C);
  static const Color surfaceElevated = Color(0xFF1E1F24);
  static const Color surfaceOverlay = Color(0xFF2A2C33);
  static const Color border = Color(0xFF2E3038);

  // Surfaces (light)
  static const Color surfaceLight = Color(0xFFF6F8FA);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFD0D7DE);

  // Brand
  static const Color primary = Color(0xFF2F81F7);
  static const Color secondary = Color(0xFF3FB950);

  // Git semantic colours
  static const Color added = Color(0xFF3FB950);
  static const Color modified = Color(0xFFD29922);
  static const Color deleted = Color(0xFFF85149);
  static const Color conflicted = Color(0xFFDB61A2);
  static const Color untracked = Color(0xFF8B949E);

  static const Color textPrimary = Color(0xFFCDD9E5);
  static const Color textSecondary = Color(0xFF8B949E);
}
