import 'package:flutter/material.dart';

/// Design tokens for TeachLearn's "Royal Blue" design system.
class AppColors {
  // Light Mode Tokens (Royal Blue Palette)
  static const Color primary = Color(0xFF1D3FBB); // Primary Royal Blue (#1D3FBB)
  static const Color secondary = Color(0xFF5B7CFA); // Light Accent Blue (#5B7CFA)
  static const Color backgroundLight = Color(0xFFF6F7FB); // Soft Blue-Grey (#F6F7FB)
  static const Color surfaceLight = Color(0xFFFFFFFF); // Clean Surface White (#FFFFFF)
  static const Color ink = Color(0xFF12172B); // Deep Navy Text (#12172B)
  static const Color inkMuted = Color(0xFF5E6782); // Muted Secondary Text
  static const Color borderLight = Color(0xFFE2E6F0); // Subtle Divider & Border

  // Dark Mode Tokens (Deep Navy Palette)
  static const Color primaryLight = Color(0xFF5B7CFA); // Accessible Dark-mode Blue
  static const Color backgroundDark = Color(0xFF0E1324); // Deep Navy
  static const Color surfaceDark = Color(0xFF171E36); // Raised Deep Surface
  static const Color darkInk = Color(0xFFF6F7FB); // High-contrast Light Text
  static const Color darkInkMuted = Color(0xFFA1ACC7); // Secondary Dark Text
  static const Color borderDark = Color(0xFF252F52); // Dark Border

  // Backward-compatibility Aliases
  static const Color primaryTeal = primary;
  static const Color primaryTealLight = primaryLight;
  static const Color accentTeal = secondary;

  // Semantic Status Colors
  static const Color success = Color(0xFF2E9D6B); // Present / Success
  static const Color successSurface = Color(0xFFEBF7F2);
  static const Color darkSuccessSurface = Color(0xFF142B21);

  static const Color warning = Color(0xFFD97706); // Late / Pending
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color darkWarningSurface = Color(0xFF2B2113);

  static const Color danger = Color(0xFFD64545); // Absent / Danger
  static const Color dangerSurface = Color(0xFFFDF0F0);
  static const Color darkDangerSurface = Color(0xFF2E1717);
}
