import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class JT {
  // ── Design System Colors (spec v2) ──────────────────────────────────────
  static const Color primary     = Color(0xFF2F6BFF);  // #2F6BFF
  static const Color secondary   = Color(0xFF5B8FFF);
  static const Color bg          = Color(0xFFFFFFFF);  // #FFFFFF
  static const Color bgSoft      = Color(0xFFF9FAFB);  // neutral soft bg
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surfaceAlt  = Color(0xFFF3F6FF);
  static const Color border      = Color(0xFFE5E7EB);  // #E5E7EB
  static const Color textPrimary = Color(0xFF111827);  // #111827
  static const Color textSecondary = Color(0xFF6B7280); // #6B7280
  static const Color iconInactive  = Color(0xFFD1D5DB);
  static const Color error   = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // Gradient
  static const LinearGradient grad = LinearGradient(
    colors: [Color(0xFF5B8FFF), Color(0xFF2F6BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get btnShadow => [
    BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  // Text styles
  static TextStyle get h1 => GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary);
  static TextStyle get h2 => GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary);
  static TextStyle get h3 => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get body => GoogleFonts.poppins(fontSize: 14, color: textSecondary);
  static TextStyle get bodyPrimary => GoogleFonts.poppins(fontSize: 14, color: textPrimary);
  static TextStyle get caption => GoogleFonts.poppins(fontSize: 12, color: textSecondary);
  static TextStyle get btnText => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);

  // Reusable widgets
  static Widget gradientButton({required String label, required VoidCallback onTap, bool loading = false}) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: grad,
          borderRadius: BorderRadius.circular(14),
          boxShadow: btnShadow,
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(label, style: btnText),
        ),
      ),
    );
  }

  static Widget logoBlue({double height = 36}) => _logoWidget(
        height: height,
        iconAsset: 'assets/images/jago_icon.svg',
        wordmarkColor: textPrimary,
        sublabelColor: primary,
      );

  static Widget logoWhite({double height = 36}) => _logoWidget(
        height: height,
        iconAsset: 'assets/images/jago_icon_white.svg',
        wordmarkColor: Colors.white,
        sublabelColor: Colors.white.withValues(alpha: 0.85),
      );

  static Widget _logoWidget({
    required double height,
    required String iconAsset,
    required Color wordmarkColor,
    required Color sublabelColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(iconAsset, height: height, width: height),
        SizedBox(width: height * 0.18),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JAGO',
              style: GoogleFonts.poppins(
                fontSize: height * 0.50,
                fontWeight: FontWeight.w900,
                color: wordmarkColor,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'PRO',
              style: GoogleFonts.poppins(
                fontSize: height * 0.22,
                fontWeight: FontWeight.w700,
                color: sublabelColor,
                letterSpacing: 2.5,
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
