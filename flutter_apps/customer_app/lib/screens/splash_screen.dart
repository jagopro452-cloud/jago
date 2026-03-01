import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl, _logoCtrl, _textCtrl, _pulseCtrl;
  late Animation<double> _bgFade, _logoScale, _logoFade, _textFade, _pulse;
  late Animation<Offset> _textSlide;

  static const _blue = Color(0xFF1E6DE5);
  static const _darkBlue = Color(0xFF1244A2);
  static const _deepBlue = Color(0xFF0A2040);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

    _bgFade    = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _textFade  = Tween<double>(begin: 0, end: 1).animate(_textCtrl);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _runAnims();
    _navigate();
  }

  void _runAnims() async {
    await _bgCtrl.forward();
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 180));
    _textCtrl.forward();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => token != null ? const HomeScreen() : const LoginScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _logoCtrl.dispose(); _textCtrl.dispose(); _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _logoCtrl, _textCtrl, _pulseCtrl]),
        builder: (_, __) => Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_deepBlue, _darkBlue, _blue],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: Stack(children: [
            // Decorative blobs
            Positioned(top: -size.width * 0.5, right: -size.width * 0.35,
              child: Opacity(opacity: _bgFade.value * 0.13,
                child: Container(width: size.width * 1.2, height: size.width * 1.2,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)))),
            Positioned(bottom: -size.width * 0.55, left: -size.width * 0.3,
              child: Opacity(opacity: _bgFade.value * 0.07,
                child: Container(width: size.width * 1.1, height: size.width * 1.1,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)))),
            // Diagonal line accent
            Positioned.fill(
              child: FadeTransition(
                opacity: _bgFade,
                child: CustomPaint(painter: _DiagonalPainter()),
              ),
            ),
            SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Spacer(flex: 2),
                // Logo card
                Opacity(opacity: _logoFade.value,
                  child: Transform.scale(scale: _logoScale.value,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.22),
                            blurRadius: 50, spreadRadius: 0, offset: const Offset(0, 16)),
                          BoxShadow(color: _blue.withOpacity(0.35),
                            blurRadius: 30, spreadRadius: -4, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Center(
                        child: Image.asset('assets/images/jago_logo.png', width: 75, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('JAGO',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                              color: _blue, letterSpacing: 3))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                // Brand text
                SlideTransition(position: _textSlide,
                  child: FadeTransition(opacity: _textFade,
                    child: Column(children: [
                      const Text('JAGO',
                        style: TextStyle(color: Colors.white, fontSize: 46,
                          fontWeight: FontWeight.w900, letterSpacing: 12,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 12)])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Text('Move Smarter.',
                          style: TextStyle(color: Colors.white.withOpacity(0.85),
                            fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 2.5)),
                      ),
                    ]),
                  ),
                ),
                const Spacer(flex: 3),
                // Bottom loader
                FadeTransition(opacity: _textFade,
                  child: Column(children: [
                    Transform.scale(scale: _pulse.value,
                      child: SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 1.8,
                          color: Colors.white.withOpacity(0.5),
                          backgroundColor: Colors.white.withOpacity(0.12)))),
                    const SizedBox(height: 20),
                    Text('MindWhile IT Solutions',
                      style: TextStyle(color: Colors.white.withOpacity(0.3),
                        fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w400)),
                    const SizedBox(height: 48),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (int i = -5; i < 20; i++) {
      final x = i * (size.width / 8);
      canvas.drawLine(Offset(x, 0), Offset(x + size.height * 0.5, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
