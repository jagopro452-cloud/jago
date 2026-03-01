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
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('JAGO',
                  style: TextStyle(fontSize: 58, fontWeight: FontWeight.w900,
                    color: Color(0xFF1E6DE5), letterSpacing: 5)),
                const SizedBox(height: 10),
                Text('Move Smarter.',
                  style: TextStyle(fontSize: 17, color: Colors.grey[500], letterSpacing: 0.5)),
                const SizedBox(height: 80),
                SizedBox(width: 28, height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    color: const Color(0xFF1E6DE5).withOpacity(0.35))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
