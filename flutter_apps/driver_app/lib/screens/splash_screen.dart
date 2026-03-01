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
  late AnimationController _ctrl;
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _bgFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _textFade = Tween<double>(begin: 0, end: 1).animate(_textCtrl);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _runAnimations();
    _navigate();
  }

  void _runAnimations() async {
    await _ctrl.forward();
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
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
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_ctrl, _logoCtrl, _textCtrl]),
        builder: (_, __) => Container(
          width: double.infinity, height: double.infinity,
          color: const Color(0xFF060D1E),
          child: Stack(children: [
            Positioned(
              top: -80, right: -80,
              child: Opacity(
                opacity: _bgFade.value * 0.25,
                child: Container(
                  width: size.width * 0.8, height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF2563EB), const Color(0xFF2563EB).withOpacity(0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100, left: -60,
              child: Opacity(
                opacity: _bgFade.value * 0.12,
                child: Container(
                  width: size.width * 0.7, height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF1E6DE5), const Color(0xFF1E6DE5).withOpacity(0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter(opacity: _bgFade.value * 0.03)),
            ),
            SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Spacer(flex: 2),
                Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(children: [
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B3E),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 50, spreadRadius: 5),
                          ],
                        ),
                        child: Center(
                          child: Image.asset('assets/images/pilot_logo.png',
                            width: 68, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('JAGO', style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                                Text('PILOT', style: TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.w700, color: const Color(0xFF2563EB).withOpacity(0.8), letterSpacing: 4)),
                              ],
                            )),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 32),
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('JAGO ', style: TextStyle(color: Colors.white,
                          fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6)),
                        Text('PILOT', style: TextStyle(color: const Color(0xFF2563EB),
                          fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6)),
                      ]),
                      const SizedBox(height: 8),
                      Text('Drive Smarter.', style: TextStyle(color: Colors.white.withOpacity(0.5),
                        fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 2)),
                    ]),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _textFade,
                  child: Column(children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 1.5,
                        color: const Color(0xFF2563EB).withOpacity(0.5))),
                    const SizedBox(height: 18),
                    Text('MindWhile IT Solutions',
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, letterSpacing: 0.5)),
                    const SizedBox(height: 40),
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
  final double opacity;
  _GridPainter({required this.opacity});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_GridPainter old) => old.opacity != opacity;
}
