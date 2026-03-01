import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              token != null ? const HomeScreen() : const LoginScreen(),
        ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFBDD9FF),
              Color(0xFFDEEDFF),
              Color(0xFFF5F9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _fade.value,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 190,
                      height: 116,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E6DE5).withOpacity(0.3),
                            blurRadius: 48,
                            spreadRadius: 2,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/jago_logo.png',
                          width: 118,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'JAGO',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Move Smarter.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B8EBF),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Move Smarter.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E6DE5).withOpacity(0.75),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF1E6DE5).withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Version 2.01',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
