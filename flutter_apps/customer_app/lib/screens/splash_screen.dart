import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/login');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -80, right: -80, child: Container(width: 240, height: 240, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x142563EB)))),
            Positioned(bottom: 60, left: -60, child: Container(width: 200, height: 200, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x0A2563EB)))),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (_, child) => Transform.translate(offset: Offset(0, _slide.value), child: child),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                        ),
                        child: const Center(child: Text('J', style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                      const SizedBox(height: 20),
                      const Text('JAGO', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), letterSpacing: 4)),
                      const SizedBox(height: 6),
                      const Text('Ride Smart. Ride Safe.', style: TextStyle(fontSize: 14, color: Color(0xFF3B82F6), letterSpacing: 1)),
                      const SizedBox(height: 48),
                      const SizedBox(width: 40, height: 3, child: LinearProgressIndicator(
                        backgroundColor: Color(0xFFBFDBFE),
                        valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(bottom: 28, left: 0, right: 0, child: Text('MindWhile IT Solutions Pvt Ltd', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF93C5FD)))),
          ],
        ),
      ),
    );
  }
}
