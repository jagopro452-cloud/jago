import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home/home_screen.dart';
import 'auth/login_screen.dart';
import 'onboarding/language_select_screen.dart';
import 'onboarding/driver_onboarding_screen.dart';

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
  late AnimationController _glowCtrl;

  static const _bg = Color(0xFF060A14);
  static const _surface = Color(0xFF0F1923);
  static const _primary = Color(0xFF00D4FF);
  static const _green = Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.65)));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..forward();

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _runSequence();
    _navigate();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textCtrl.forward();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('driver_onboarding_seen') ?? false;
    if (!onboardingSeen) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DriverOnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ));
      return;
    }
    final langSelected = prefs.getBool('language_selected') ?? false;
    if (!langSelected) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageSelectScreen()));
      return;
    }
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => (token != null && token.isNotEmpty) ? const HomeScreen() : const LoginScreen(),
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: _bg,
        child: Stack(
          children: [
            // Background radial glows
            Positioned(
              top: -size.height * 0.18,
              left: size.width * 0.1,
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  width: size.width * 0.9,
                  height: size.width * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primary.withValues(alpha: 0.06 + _glowCtrl.value * 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              right: -size.width * 0.15,
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _green.withValues(alpha: 0.05 + _glowCtrl.value * 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Grid lines for premium feel
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo container with neon glow
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoCtrl, _glowCtrl]),
                    builder: (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(scale: _logoScale.value, child: child),
                    ),
                    child: AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, child) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: _surface,
                          border: Border.all(color: _primary.withValues(alpha: 0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.35 + _glowCtrl.value * 0.2),
                              blurRadius: 40 + _glowCtrl.value * 20,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.15),
                              blurRadius: 80,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/images/pilot_logo.png',
                          fit: BoxFit.contain,
                          color: Colors.white,
                          errorBuilder: (_, __, ___) => Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [_primary, Color(0xFF00A8CC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'J',
                                style: GoogleFonts.poppins(
                                  fontSize: 60, fontWeight: FontWeight.w900,
                                  color: Colors.white, height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Text section
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, child) => SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(opacity: _textOpacity, child: child),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'PILOT',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_primary, Color(0xFF00FFCC)],
                          ).createShader(bounds),
                          child: Text(
                            'Earn. Drive. Grow.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom section: progress bar + company
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) => Container(
                      height: 2,
                      child: LinearProgressIndicator(
                        value: _progressCtrl.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        valueColor: AlwaysStoppedAnimation<Color>(_primary),
                        minHeight: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Mindwhile IT Solutions Pvt Ltd',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 11, letterSpacing: 0.8,
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.025)
      ..strokeWidth = 1;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
