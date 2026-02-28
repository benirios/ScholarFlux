import 'package:flutter/material.dart';

/// Color tokens – Liquid Glass dark theme
abstract final class AppColors {
  // Backgrounds
  static const Color scaffoldBg = Color(0xFF0A0A0F);
  static const Color surfaceCard = Color(0xFF1A1A1F);
  static const Color surfaceCardLight = Color(0xFF242429);

  // Glass
  static const Color glassFill = Color(0x1AFFFFFF);       // 10% white
  static const Color glassBorder = Color(0x1AFFFFFF);     // 10% white
  static const Color glassHighlight = Color(0x0DFFFFFF);  // 5% white top edge

  // Primary
  static const Color primary = Color(0xFF5A8AF2);
  static const Color primaryLight = Color(0xFF7EAAFF);
  static const Color primaryGlow = Color(0x335A8AF2);     // 20% primary for glow

  // Text
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF5A5A5E);

  // Chips / pills
  static const Color chipDefault = Color(0x1AFFFFFF);
  static const Color chipActive = primary;

  // Divider / border
  static const Color divider = Color(0x14FFFFFF);
  static const Color border = Color(0x1AFFFFFF);

  // Semantic
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
}
