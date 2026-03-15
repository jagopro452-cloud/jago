import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late AnimationController _textCtrl;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;

  late AnimationController _progressCtrl;

  static const _bg1 = Color(0xFF0A1628);
  static const _bg2 = Color(0xFF1A2F5E);
  static const _accent = Color(0xFF2F80ED);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.7)));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..forward();

    _runSequence();
    _navigate();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    final token = prefs.getString('auth_token');
    if (!mounted) return;

    Widget destination;
    if (!onboardingSeen) {
      destination = const OnboardingScreen();
    } else if (token != null && token.isNotEmpty) {
      final profile = await AuthService.getProfile();
      if (!mounted) return;
      if (profile != null) {
        destination = const HomeScreen();
      } else {
        await prefs.remove('auth_token');
        await prefs.remove('user_data');
        destination = const LoginScreen();
      }
    } else {
      destination = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => destination,
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg1, _bg2, Color(0xFF0D2444)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background glow circle
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(scale: _logoScale.value, child: child),
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [_accent, Color(0xFF1A6FE0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.45),
                            blurRadius: 40,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/jago_logo.png',
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_accent, Color(0xFF1A6FE0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Text('J',
                                style: GoogleFonts.poppins(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                )),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            // Bottom: progress bar + company
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thin progress bar
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _progressCtrl.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Mindwhile IT Solutions Pvt Ltd',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
