import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
}

ThemeData buildAidLinkTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primaryDark,
    onSecondary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    visualDensity: VisualDensity.standard,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: text.bodyMedium?.copyWith(
        color: AppColors.textMuted,
        height: 1.45,
      ),
      bodySmall: text.bodySmall?.copyWith(
        color: AppColors.textMuted,
        height: 1.4,
      ),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 60,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textSubtle),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      helperStyle: const TextStyle(color: AppColors.textMuted),
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSubtle,
        elevation: 0,
        minimumSize: const Size(44, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(44, 48),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.borderStrong),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: AppColors.nav,
      surfaceTintColor: AppColors.nav,
      indicatorColor: AppColors.primarySoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
          size: 22,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
