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
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF060D1E),
              Color(0xFF0A1830),
              Color(0xFF0E2040),
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
                    child: Column(
                      children: [
                        Container(
                          width: 190,
                          height: 116,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B3E),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: const Color(0xFF2563EB).withOpacity(0.2),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF2563EB).withOpacity(0.25),
                                blurRadius: 48,
                                spreadRadius: 4,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/pilot_logo.png',
                              width: 118,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'JAGO',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'PILOT',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                      letterSpacing: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Drive Smarter.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.55),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF2563EB).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Version 2.01',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.25),
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
