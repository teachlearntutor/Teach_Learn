import 'package:flutter/material.dart';

class AppTypography {
  static const String headingFontFamily = 'BricolageGrotesque';
  static const String bodyFontFamily = 'Onest';

  static TextTheme createTextTheme(Color textColor, Color mutedColor) {
    TextStyle heading(double size, FontWeight weight, {double height = 1.2}) =>
        TextStyle(
          fontFamily: headingFontFamily,
          fontSize: size,
          fontWeight: weight,
          color: textColor,
          height: height,
          fontVariations: [FontVariation('wght', weight.value.toDouble())],
        );

    TextStyle body(
      double size,
      FontWeight weight,
      Color color, {
      double height = 1.4,
    }) => TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );

    return TextTheme(
      displayLarge: heading(34, FontWeight.w700, height: 1.15),
      displayMedium: heading(28, FontWeight.w700),
      displaySmall: heading(24, FontWeight.w700, height: 1.25),
      headlineLarge: heading(22, FontWeight.w700),
      headlineMedium: heading(20, FontWeight.w600),
      headlineSmall: heading(18, FontWeight.w600),
      titleLarge: body(18, FontWeight.w600, textColor),
      titleMedium: body(16, FontWeight.w600, textColor),
      titleSmall: body(14, FontWeight.w600, textColor),
      bodyLarge: body(16, FontWeight.w400, textColor, height: 1.5),
      bodyMedium: body(14, FontWeight.w400, textColor, height: 1.45),
      bodySmall: body(12, FontWeight.w400, mutedColor),
      labelLarge: body(15, FontWeight.w600, textColor),
      labelMedium: body(13, FontWeight.w600, textColor),
      labelSmall: body(11, FontWeight.w600, mutedColor),
    );
  }
}
