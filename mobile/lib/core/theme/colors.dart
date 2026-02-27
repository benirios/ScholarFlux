import 'package:flutter/material.dart';

/// Color tokens extracted from Reference.png
abstract final class AppColors {
  // Backgrounds
  static const Color scaffoldBg = Color(0xFF0D0D11);
  static const Color surfaceCard = Color(0xFF1A1A1F);
  static const Color surfaceCardLight = Color(0xFF242429);

  // Primary (blue accent used for active states, dates, grades)
  static const Color primary = Color(0xFF4A7BF7);
  static const Color primaryLight = Color(0xFF6B9AFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF5A5A5E);

  // Chips / pills
  static const Color chipDefault = Color(0xFF2C2C30);
  static const Color chipActive = primary;

  // Divider / border
  static const Color divider = Color(0xFF2C2C30);
  static const Color border = Color(0xFF3A3A3E);

  // Semantic
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
}
