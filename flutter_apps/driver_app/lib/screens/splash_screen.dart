import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/language_select_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl, _pulseCtrl, _ringCtrl;
  late Animation<double> _logoScale, _logoFade, _pulse, _ringExpand;

  static const _bg      = Color(0xFF060D1E);
  static const _surface = Color(0xFF0D1B3E);
  static const _primary = Color(0xFF1E6DE5);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _ringCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();

    _logoScale = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _pulse = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _ringExpand = Tween<double>(begin: 0.7, end: 1.5)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () => _logoCtrl.forward());
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final langSelected = prefs.getBool('language_selected') ?? false;
    if (!mounted) return;
    Widget next;
    if (!langSelected) {
      next = const LanguageSelectScreen();
    } else if (token != null) {
      next = const HomeScreen();
    } else {
      next = const LoginScreen();
    }
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => next,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoCtrl, _pulseCtrl, _ringCtrl]),
        builder: (_, __) => SizedBox.expand(
          child: Stack(alignment: Alignment.center, children: [
            // Radial glow top-right
            Positioned(
              top: -80, right: -80,
              child: Opacity(
                opacity: _logoFade.value * 0.22,
                child: Container(
                  width: size.width * 0.9, height: size.width * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_primary, _primary.withOpacity(0)]),
                  ),
                ),
              ),
            ),
            // Grid pattern
            Positioned.fill(
              child: Opacity(
                opacity: _logoFade.value * 0.03,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
            // Animated expanding ring
            Opacity(
              opacity: (1 - _ringExpand.value / 1.5) * 0.20 * _logoFade.value,
              child: Transform.scale(
                scale: _ringExpand.value,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primary, width: 1.5),
                  ),
                ),
              ),
            ),
            // Center pilot logo
            Opacity(
              opacity: _logoFade.value,
              child: Transform.scale(
                scale: _logoScale.value * _pulse.value,
                child: Container(
                  width: size.width * 0.52,
                  height: size.width * 0.52,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(size.width * 0.14),
                    border: Border.all(color: _primary.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: _primary.withOpacity(0.28), blurRadius: 60, spreadRadius: 5),
                      BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 25),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/pilot_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/jago_logo_white.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const _FallbackPilotLogo(),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom powered-by text
            Positioned(
              bottom: 48,
              left: 0, right: 0,
              child: Opacity(
                opacity: _logoFade.value * 0.35,
                child: const Text(
                  'MindWheel IT Solutions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FallbackPilotLogo extends StatelessWidget {
  const _FallbackPilotLogo();
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('JAGO', style: TextStyle(color: Colors.white, fontSize: 28,
        fontWeight: FontWeight.w900, letterSpacing: 4)),
      const SizedBox(height: 4),
      Text('PILOT', style: TextStyle(color: Color(0xFF1E6DE5), fontSize: 14,
        fontWeight: FontWeight.w900, letterSpacing: 6)),
    ]);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
