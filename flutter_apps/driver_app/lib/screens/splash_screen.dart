import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'home/home_screen.dart';
import 'auth/login_screen.dart';
import 'onboarding/language_select_screen.dart';
import 'onboarding/driver_onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const Color _blue = Color(0xFF2F80ED);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeCtrl.forward();
    });

    _navigate();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('driver_onboarding_seen') ?? false;
    if (!onboardingSeen) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DriverOnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
      return;
    }
    final langSelected = prefs.getBool('language_selected') ?? false;
    if (!langSelected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LanguageSelectScreen()),
      );
      return;
    }
    final token = prefs.getString('auth_token');
    final loggedIn = token != null && token.isNotEmpty;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => loggedIn ? const HomeScreen() : const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Blue gradient accent — top edge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.18,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2F80ED), Colors.white],
                ),
              ),
            ),
          ),
          // Blue gradient accent — bottom edge
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.14,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF2F80ED), Colors.white],
                ),
              ),
            ),
          ),
          // Center content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pilot logo with blue drop shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.28),
                          blurRadius: 36,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/pilot_logo.png',
                      width: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildFallbackLogo(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // JAGO Pilot bold blue text
                  Text(
                    'JAGO Pilot',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _blue,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tagline in grey
                  Text(
                    'Drive. Deliver. Earn.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom: Mindwhile IT Solutions Pvt Ltd
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'Mindwhile IT Solutions Pvt Ltd',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFCBD5E1),
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          'P',
          style: GoogleFonts.poppins(
            fontSize: 100,
            fontWeight: FontWeight.w900,
            color: _blue,
            height: 1,
          ),
        ),
      ),
    );
  }
}
