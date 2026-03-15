import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // New premium dark palette
  static const bg = Color(0xFF060A14);
  static const surface = Color(0xFF0F1923);
  static const card = Color(0xFF162030);
  static const border = Color(0xFF1E3050);

  // Neon accents
  static const primary = Color(0xFF00D4FF);       // neon cyan
  static const green = Color(0xFF00E676);          // neon green
  static const amber = Color(0xFFFFB300);          // gold
  static const red = Color(0xFFFF3D57);            // neon red

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8899BB);
  static const textHint = Color(0xFF445577);

  // Legacy aliases (keep for backward compat)
  static const primary_ = primary;
  static const primaryDark = Color(0xFF00A8CC);
  static const primaryLight = Color(0xFFE0FAFF);
  static const darkBg = bg;
  static const darkCard = card;
  static const darkSurface = surface;
  static const darkBorder = border;
  static const lightBg = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF8FAFC);
  static const lightBorder = Color(0xFFE2E8F0);
  static const textWhite = textPrimary;
  static const textSub = textSecondary;
  static const textMuted = textHint;
  static const textDark = Color(0xFF1E293B);
  static const purple = Color(0xFF8B5CF6);
  static const orange = amber;
}

class AppText {
  static TextStyle heading(BuildContext context) => GoogleFonts.poppins(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle subheading(BuildContext context) => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle body(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle label(BuildContext context) => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle statBig({Color color = AppColors.textPrimary}) => GoogleFonts.poppins(
    fontSize: 32, fontWeight: FontWeight.w900,
    color: color, letterSpacing: -1,
  );
}

class AppCard {
  static BoxDecoration dark({double radius = 16}) => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border, width: 1),
  );

  static BoxDecoration neonBorder({double radius = 16, Color color = AppColors.primary}) => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
    boxShadow: [
      BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
    ],
  );

  static BoxDecoration gradient({double radius = 16}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
  );

  static BoxDecoration light({double radius = 16}) => BoxDecoration(
    color: AppColors.lightCard,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.lightBorder, width: 1),
  );
}

class AppGlow {
  static List<BoxShadow> neon(Color color, {double blur = 20, double spread = 0}) => [
    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: blur, spreadRadius: spread),
    BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: blur * 2.5, spreadRadius: spread),
  ];

  static List<BoxShadow> soft(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 4)),
  ];
}
