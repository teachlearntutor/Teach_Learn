import 'package:flutter/material.dart';

/// Design tokens for TeachLearn's "Calm, Modern, Premium" design system.
class AppColors {
  // Light Mode Tokens
  static const Color backgroundLight = Color(0xFFFAF9F6); // Warm off-white
  static const Color surfaceLight = Color(0xFFFFFFFF); // Clean surface white
  static const Color ink = Color(0xFF14201C); // Deep ink text
  static const Color inkMuted = Color(0xFF6B7771); // Secondary muted text
  static const Color borderLight = Color(0xFFE8E6E1); // Subtle divider & border

  // Dark Mode Tokens
  static const Color backgroundDark = Color(0xFF0B1211); // Near-black green
  static const Color surfaceDark = Color(0xFF121C1A); // Raised dark surface
  static const Color darkInk = Color(0xFFFAF9F6); // High-contrast paper text
  static const Color darkInkMuted = Color(0xFF91A09A); // Secondary dark text
  static const Color borderDark = Color(0xFF1F2E2A); // Dark border

  // Brand Colors
  static const Color primaryTeal = Color(0xFF0E5C54); // Deep calm teal
  static const Color primaryTealLight = Color(
    0xFF1EA293,
  ); // Dark-mode accessible teal
  static const Color accentTeal = Color(0xFF66D6C6);

  // Semantic Status Colors
  static const Color success = Color(0xFF2E9D6B); // Paid / Present
  static const Color successSurface = Color(0xFFEAF5F0);
  static const Color darkSuccessSurface = Color(0xFF132A20);

  static const Color warning = Color(0xFF087C70); // Partial / Late
  static const Color warningSurface = Color(0xFFE7F4F1);
  static const Color darkWarningSurface = Color(0xFF15342F);

  static const Color danger = Color(0xFFD64545); // Unpaid / Absent
  static const Color dangerSurface = Color(0xFFFDF0F0);
  static const Color darkDangerSurface = Color(0xFF2E1717);
}
