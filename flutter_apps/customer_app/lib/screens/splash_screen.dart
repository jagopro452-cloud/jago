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
  late AnimationController _logoCtrl, _pulseCtrl;
  late Animation<double> _logoScale, _logoFade, _pulse;

  static const _navy     = Color(0xFF060D1E);
  static const _navyMid  = Color(0xFF1C1C1E);
  static const _navyDeep = Color(0xFF040A14);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _pulse = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 200), () => _logoCtrl.forward());
    _navigate();
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
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _navy,
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
        builder: (_, __) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_navyMid, _navy, _navyDeep],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(children: [
            Positioned(
              top: -size.width * 0.55,
              right: -size.width * 0.45,
              child: Opacity(
                opacity: 0.08,
                child: Container(
                  width: size.width * 1.2, height: size.width * 1.2,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF6200),
                  ),
                ),
              ),
            ),
            // Subtle glow blob — bottom left
            Positioned(
              bottom: -size.width * 0.5,
              left: -size.width * 0.3,
              child: Opacity(
                opacity: 0.06,
                child: Container(
                  width: size.width, height: size.width,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: size.height * 0.25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFFF6200).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Center logo
            Center(
              child: Opacity(
                opacity: _logoFade.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Transform.scale(
                    scale: _pulse.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/jago_logo_white.png',
                          width: size.width * 0.58,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/jago_logo.png',
                            width: size.width * 0.58,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const _FallbackLogo(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _logoFade.value * 0.7,
                          child: Container(
                            width: 48, height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6200), Colors.white],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
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
                opacity: _logoFade.value * 0.4,
                child: const Text(
                  'MindWheel IT Solutions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.8,
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

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(children: [
        TextSpan(text: 'JA', style: TextStyle(color: Color(0xFFFF6200), fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 4)),
        TextSpan(text: 'GO', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 4)),
      ]),
    );
  }
}
