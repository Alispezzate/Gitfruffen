import 'package:flutter/material.dart';

/// Centralised colour palette for Gitfruffen.
///
/// The palette intentionally mirrors a desktop Git client: deep neutral
/// surfaces, a violet primary accent and semantic colours for Git states.
abstract final class AppColors {
  // Surfaces (dark)
  static const Color surface = Color(0xFF1B1D23);
  static const Color surfaceElevated = Color(0xFF23262E);
  static const Color surfaceOverlay = Color(0xFF2C303A);
  static const Color border = Color(0xFF343945);

  // Surfaces (light)
  static const Color surfaceLight = Color(0xFFF7F7FA);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE0E2E8);

  // Brand
  static const Color primary = Color(0xFF8B7CF6);
  static const Color secondary = Color(0xFF3DD9B0);

  // Git semantic colours
  static const Color added = Color(0xFF3DD9B0);
  static const Color modified = Color(0xFFF0B44C);
  static const Color deleted = Color(0xFFF06C7A);
  static const Color conflicted = Color(0xFFE05C9A);
  static const Color untracked = Color(0xFF7C8899);

  static const Color textPrimary = Color(0xFFECEFF4);
  static const Color textSecondary = Color(0xFF9BA3B4);
}
