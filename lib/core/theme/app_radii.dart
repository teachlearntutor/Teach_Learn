import 'package:flutter/material.dart';

/// Corner radius tokens for Royal Blue design system.
class AppRadii {
  static const double card = 12.0;
  static const double sheet = 16.0;
  static const double button = 10.0;
  static const double input = 10.0;
  static const double chip = 8.0;

  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius inputBorderRadius = BorderRadius.all(Radius.circular(input));
  static const BorderRadius chipBorderRadius = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius sheetBorderRadius = BorderRadius.vertical(top: Radius.circular(sheet));
}
