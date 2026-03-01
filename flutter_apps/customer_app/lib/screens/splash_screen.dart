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
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _textFade = Tween<double>(begin: 0, end: 1).animate(_textCtrl);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _runAnimations();
    _navigate();
  }

  void _runAnimations() async {
    await _bgCtrl.forward();
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
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
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _logoCtrl, _textCtrl]),
        builder: (_, __) => Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A2040), Color(0xFF1244A2), Color(0xFF1E6DE5)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(children: [
            Positioned(
              top: -size.width * 0.4, right: -size.width * 0.3,
              child: Opacity(
                opacity: _bgAnim.value * 0.12,
                child: Container(width: size.width * 1.1, height: size.width * 1.1,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.5, left: -size.width * 0.3,
              child: Opacity(
                opacity: _bgAnim.value * 0.07,
                child: Container(width: size.width * 1.2, height: size.width * 1.2,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
              ),
            ),
            SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Spacer(flex: 2),
                Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 14))],
                      ),
                      child: Center(
                        child: Image.asset('assets/images/jago_logo.png',
                          width: 68, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('JAGO',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                              color: Color(0xFF1E6DE5), letterSpacing: 2))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(children: [
                      const Text('JAGO',
                        style: TextStyle(color: Colors.white, fontSize: 40,
                          fontWeight: FontWeight.w900, letterSpacing: 10)),
                      const SizedBox(height: 6),
                      Text('Move Smarter.',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14,
                          fontWeight: FontWeight.w400, letterSpacing: 2)),
                    ]),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _textFade,
                  child: Column(children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white.withOpacity(0.4))),
                    const SizedBox(height: 18),
                    Text('MindWhile IT Solutions',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, letterSpacing: 0.5)),
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
