import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography tokens matching the Reference.png style
abstract final class AppTypography {
  static const String _fontFamily = 'SF Pro Display';

  // Large header — "26 de junho, quinta"
  static const TextStyle headerLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // Header accent — the blue weekday part ("quinta")
  static const TextStyle headerAccent = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: -0.3,
  );

  // Section title — "Aulas", "Trabalhos futuros"
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  // Card title — subject name, item title
  static const TextStyle cardTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Card subtitle — room, time, domain values
  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Badge / grade text — "Média-10", "Nota-15", "Sala-LP2"
  static const TextStyle badge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // Date label in future work list
  static const TextStyle dateLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  // Day number on calendar grid
  static const TextStyle calendarDay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Chip label — "Seg", "Ter", "Jan", etc.
  static const TextStyle chip = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Small caption — domain labels "D1-15,00", etc.
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
