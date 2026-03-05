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
  late AnimationController _bgCtrl, _logoCtrl, _textCtrl, _pulseCtrl, _ringCtrl;
  late Animation<double> _bgFade, _logoScale, _logoFade, _textFade, _ringExpand;
  late Animation<Offset> _textSlide;

  static const _bg     = Color(0xFF060D1E);
  static const _surface= Color(0xFF0D1B3E);
  static const _blue   = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _ringCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();

    _bgFade    = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _textFade  = Tween<double>(begin: 0, end: 1).animate(_textCtrl);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _ringExpand = Tween<double>(begin: 0.7, end: 1.4).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    _runAnims();
    _navigate();
  }

  void _runAnims() async {
    await _bgCtrl.forward();
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _textCtrl.forward();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final langSelected = prefs.getBool('language_selected') ?? false;
    if (!mounted) return;
    Widget nextScreen;
    if (!langSelected) {
      nextScreen = const LanguageSelectScreen();
    } else if (token != null) {
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const LoginScreen();
    }
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => nextScreen,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _logoCtrl.dispose(); _textCtrl.dispose();
    _pulseCtrl.dispose(); _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _logoCtrl, _textCtrl, _pulseCtrl, _ringCtrl]),
        builder: (_, __) => SizedBox.expand(
          child: Stack(alignment: Alignment.center, children: [
            // Radial glow top-right
            Positioned(top: -80, right: -80,
              child: Opacity(opacity: _bgFade.value * 0.28,
                child: Container(
                  width: size.width * 0.85, height: size.width * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_blue, _blue.withOpacity(0)]),
                  ),
                ))),
            // Grid pattern
            Positioned.fill(
              child: Opacity(
                opacity: _bgFade.value * 0.035,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
            // Animated ring
            Opacity(
              opacity: (1 - _ringExpand.value / 1.4) * 0.25 * _bgFade.value,
              child: Transform.scale(scale: _ringExpand.value,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _blue, width: 1.5),
                  ),
                )),
            ),
            SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Spacer(flex: 2),
                // Logo
                Opacity(opacity: _logoFade.value,
                  child: Transform.scale(scale: _logoScale.value,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(color: _blue.withOpacity(0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: _blue.withOpacity(0.35), blurRadius: 55, spreadRadius: 5),
                          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
                        ],
                      ),
                      child: Center(
                        child: Image.asset('assets/images/pilot_logo.png', width: 72, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('JAGO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                                color: Colors.white, letterSpacing: 3)),
                              Text('PILOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: _blue, letterSpacing: 5)),
                            ],
                          )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // Text
                SlideTransition(position: _textSlide,
                  child: FadeTransition(opacity: _textFade,
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('JAGO ', style: TextStyle(color: Colors.white,
                          fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 7)),
                        Text('PILOT', style: TextStyle(color: _blue,
                          fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 7)),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: _blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _blue.withOpacity(0.2), width: 1),
                        ),
                        child: Text('Drive Smarter.',
                          style: TextStyle(color: Colors.white.withOpacity(0.6),
                            fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 2.5)),
                      ),
                    ]),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(opacity: _textFade,
                  child: Column(children: [
                    SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 1.8,
                        color: _blue.withOpacity(0.6), backgroundColor: _blue.withOpacity(0.1))),
                    const SizedBox(height: 18),
                    Text('MindWhile IT Solutions',
                      style: TextStyle(color: Colors.white.withOpacity(0.25),
                        fontSize: 11, letterSpacing: 0.5)),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 0.5;
    const step = 28.0;
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
