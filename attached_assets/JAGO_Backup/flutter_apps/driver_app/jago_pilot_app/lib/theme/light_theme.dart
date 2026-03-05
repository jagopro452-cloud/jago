import 'package:flutter/material.dart';
import 'package:jago_pilot_app/theme/custom_theme_colors.dart';

ThemeData lightTheme = ThemeData(
    fontFamily: 'SFProText',
    primaryColor: const Color(0xFF2563EB),
    disabledColor: const Color(0xFFBABFC4),
    primaryColorDark: const Color(0xFF1E3A8A),
    brightness: Brightness.light,
    hintColor: const Color(0xFF94A3B8),
    cardColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    canvasColor: Colors.white,
    shadowColor: Colors.black.withValues(alpha: 0.06),
    splashColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
    highlightColor: const Color(0xFF2563EB).withValues(alpha: 0.04),

    extensions: <ThemeExtension<CustomThemeColors>>[
      CustomThemeColors.light()
    ],

    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      centerTitle: true,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 12,
      selectedItemColor: Color(0xFF2563EB),
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.fixed,
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      surface: Color(0xFFF8FAFC),
      error: Color(0xFFEF4444),
      secondary: Color(0xFF1D4ED8),
      tertiary: Color(0xFF10B981),
      tertiaryContainer: Color(0xFFF59E0B),
      secondaryContainer: Color(0xFFEF4444),
      onTertiary: Color(0xFFE2E8F0),
      onSecondary: Color(0xFF93C5FD),
      onSecondaryContainer: Color(0xFF93C5FD),
      onTertiaryContainer: Color(0xFF475569),
      outline: Color(0xFFBFDBFE),
      onPrimaryContainer: Color(0xFFEFF6FF),
      primaryContainer: Color(0xFFF59E0B),
      onErrorContainer: Color(0xFFFEF3C7),
      onPrimary: Color(0xFF2563EB),
      surfaceTint: Color(0xFF10B981),
      errorContainer: Color(0xFFF8FAFC),
      shadow: Color(0xFFE2E8F0),
      surfaceContainer: Color(0xFF0EA5E9),
      secondaryFixedDim: Color(0xFF94A3B8),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 16,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      displayMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      displaySmall: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155)),
      bodyLarge: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF334155)),
      bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF1E293B)),
      bodySmall: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF64748B)),
    ),
);
