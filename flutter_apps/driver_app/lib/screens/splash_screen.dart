import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => token != null ? const HomeScreen() : const LoginScreen(),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _fade.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('JAGO',
                  style: TextStyle(fontSize: 58, fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB), letterSpacing: 5)),
                const SizedBox(height: 6),
                const Text('PILOT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: Colors.white, letterSpacing: 8)),
                const SizedBox(height: 8),
                Text('Drive Smarter.',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4), letterSpacing: 0.5)),
                const SizedBox(height: 80),
                SizedBox(width: 28, height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    color: const Color(0xFF2563EB).withOpacity(0.4))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
