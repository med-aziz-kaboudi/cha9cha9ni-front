import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFEE3764);
  static const Color secondary = Color(0xFF4CC3C7);
  static const Color dark = Color(0xFF252934);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFFFAFAFA);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [primary, primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [secondary, secondary],
  );
}

