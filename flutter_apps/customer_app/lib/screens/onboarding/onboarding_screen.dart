import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _current = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _blue = Color(0xFF2F80ED);
  static const _navy = Color(0xFF0B0B0B);

  static const _slides = [
    _Slide(
      icon: '🚗',
      gradient: [Color(0xFF2F80ED), Color(0xFF1A6FE0)],
      title: 'Book Rides Instantly',
      subtitle: 'Choose from Auto, Bike, Car, or SUV. Get a driver at your doorstep in minutes with real-time tracking.',
      features: ['Auto • Bike • Car • SUV', 'Real-time driver tracking', 'Cashless & easy payments'],
    ),
    _Slide(
      icon: '📦',
      gradient: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      title: 'Send Parcels Fast',
      subtitle: 'Door-to-door parcel delivery with live tracking. Send documents, packages, and goods hassle-free.',
      features: ['Same-day delivery', 'Live parcel tracking', 'Safe & insured delivery'],
    ),
    _Slide(
      icon: '🤝',
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      title: 'Save with Ride Pool',
      subtitle: 'Share rides with co-passengers heading the same way. Cut costs by up to 50% while reducing traffic.',
      features: ['Up to 50% savings', 'Verified co-passengers', 'Eco-friendly travel'],
    ),
    _Slide(
      icon: '🛡️',
      gradient: [Color(0xFFD97706), Color(0xFFB45309)],
      title: 'Safe & Reliable',
      subtitle: 'Verified drivers, SOS emergency button, live trip sharing, and 24/7 customer support — always with you.',
      features: ['Verified & rated drivers', 'SOS emergency button', '24/7 support'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ));
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];
    final isLast = _current == _slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: slide.gradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page dots
                      Row(
                        children: List.generate(_slides.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _current ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _current ? Colors.white : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: Text('Skip', style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) {
                      _fadeCtrl.reset();
                      setState(() => _current = i);
                      _fadeCtrl.forward();
                    },
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _SlidePage(slide: _slides[i], fadeAnim: _fadeAnim),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: slide.gradient[0],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isLast ? 'Get Started →' : 'Next →',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _finish,
                          child: Text('Skip to Login',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final Animation<double> fadeAnim;
  const _SlidePage({required this.slide, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large emoji icon with glass card
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(
                child: Text(slide.icon, style: const TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 36),
            // Title
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            // Subtitle
            Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            // Feature chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: slide.features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Text(f, style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final String icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final List<String> features;
  const _Slide({required this.icon, required this.gradient, required this.title, required this.subtitle, required this.features});
}
