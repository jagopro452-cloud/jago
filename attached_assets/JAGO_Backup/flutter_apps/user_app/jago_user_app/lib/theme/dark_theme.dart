import 'package:flutter/material.dart';
import 'package:jago_user_app/theme/custom_theme_color.dart';
import 'package:jago_user_app/util/app_constants.dart';

ThemeData darkTheme = ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: const Color(0xFF2563EB),
  primaryColorDark: const Color(0xFF1E3A8A),
  disabledColor: const Color(0xFF475569),
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  canvasColor: const Color(0xFF1E293B),
  shadowColor: Colors.black.withValues(alpha: 0.3),
  splashColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
  highlightColor: const Color(0xFF2563EB).withValues(alpha: 0.06),
  brightness: Brightness.dark,
  hintColor: const Color(0xFF64748B),
  cardColor: const Color(0xFF1E293B),
  cardTheme: CardThemeData(
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    color: const Color(0xFF1E293B),
    margin: const EdgeInsets.symmetric(vertical: 4),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0.5,
    backgroundColor: Color(0xFF1E293B),
    foregroundColor: Colors.white,
    centerTitle: true,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
    bodySmall: TextStyle(color: Color(0xFF94A3B8)),
    bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
    titleMedium: TextStyle(color: Color(0xFFF8FAFC)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF334155),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF475569), width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1E293B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    elevation: 16,
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2563EB),
    error: Color(0xFFEF4444),
    surface: Color(0xFF1E293B),
    secondary: Color(0xFF1D4ED8),
    tertiary: Color(0xFF10B981),
    tertiaryContainer: Color(0xFFF59E0B),
    secondaryContainer: Color(0xFFEF4444),
    onTertiary: Color(0xFF334155),
    onSecondary: Color(0xFF93C5FD),
    onSecondaryContainer: Color(0xFF93C5FD),
    onTertiaryContainer: Color(0xFF94A3B8),
    outline: Color(0xFF475569),
    onPrimaryContainer: Color(0xFF94A3B8),
    primaryContainer: Color(0xFFF59E0B),
    onSurface: Color(0xFFE2E8F0),
    onPrimary: Color(0xFF2563EB),
    inverseSurface: Color(0xFF0148AF),
    surfaceContainer: Color(0xFF0EA5E9),
    secondaryFixedDim: Color(0xFF64748B),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF1E293B),
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
  extensions: <ThemeExtension<CustomThemeColors>>[
    CustomThemeColors.dark(),
  ],
);
