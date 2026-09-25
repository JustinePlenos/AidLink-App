import 'package:flutter/material.dart';

/// AidLink's semantic color tokens. Green and red are deliberately reserved
/// for functional feedback so status is never communicated decoratively.
abstract final class AppColors {
  static const primary = Color(0xFF155EEF);
  static const primaryDark = Color(0xFF1849A9);
  static const primarySoft = Color(0xFFEFF4FF);

  static const success = Color(0xFF067647);
  static const successSoft = Color(0xFFECFDF3);
  static const error = Color(0xFFB42318);
  static const errorSoft = Color(0xFFFEF3F2);
  static const warning = Color(0xFFB54708);
  static const warningSoft = Color(0xFFFFFAEB);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const textSubtle = Color(0xFF94A3B8);
  static const nav = Color(0xFFFFFFFF);

  // Compatibility aliases for older screens while they adopt semantic tokens.
  static const textDark = text;
  static const textLight = Colors.white;
  static const grey = textMuted;
  static const accent = primary;
  static const gradientStart = primary;
  static const gradientEnd = primaryDark;
}
