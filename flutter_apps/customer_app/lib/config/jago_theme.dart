import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JT {
  // Colors
  static const Color primary = Color(0xFF2F7BFF);
  static const Color secondary = Color(0xFF4FA9FF);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bgSoft = Color(0xFFF7FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F5FF);
  static const Color border = Color(0xFFDDE8FF);
  static const Color textPrimary = Color(0xFF0F1829);
  static const Color textSecondary = Color(0xFF6B7FA8);
  static const Color iconInactive = Color(0xFFB0C4E8);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF1DB954);
  static const Color warning = Color(0xFFFFA726);

  // Gradient
  static const LinearGradient grad = LinearGradient(
    colors: [Color(0xFF4FA9FF), Color(0xFF2F7BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get btnShadow => [
    BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
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

  static Widget logoBlue({double height = 36}) =>
      Image.asset('assets/images/jago_logo.png', height: height, fit: BoxFit.contain);

  static Widget logoWhite({double height = 36}) =>
      Image.asset('assets/images/jago_logo_white.png', height: height, fit: BoxFit.contain);
}
