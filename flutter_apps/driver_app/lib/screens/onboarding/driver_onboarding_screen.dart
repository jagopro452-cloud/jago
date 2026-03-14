import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_select_screen.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});
  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _current = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _slides = [
    _Slide(
      icon: '📱',
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      title: 'Accept Rides Easily',
      subtitle: 'Go online with one tap. Incoming ride requests appear instantly — accept or let them pass. You\'re always in control.',
      features: ['One-tap online/offline', 'See trip details before accepting', 'Choose trips that fit your route'],
    ),
    _Slide(
      icon: '🗺️',
      gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      title: 'Navigate Every Trip',
      subtitle: 'Built-in navigation guides you door-to-door. Start, pause, and complete trips with simple buttons — no confusion.',
      features: ['Turn-by-turn navigation', 'Live trip status updates', 'Easy trip start & end flow'],
    ),
    _Slide(
      icon: '💰',
      gradient: [Color(0xFF059669), Color(0xFF047857)],
      title: 'Track Your Earnings',
      subtitle: 'Your earnings are updated after every trip. View your daily, weekly totals and withdraw directly to your bank account.',
      features: ['Instant earnings per trip', 'Daily & weekly summaries', 'Easy bank withdrawal'],
    ),
    _Slide(
      icon: '🛡️',
      gradient: [Color(0xFFD97706), Color(0xFFB45309)],
      title: 'Safety Guidelines',
      subtitle: 'Follow our safety standards: verify customer OTP before starting, keep documents updated, and use the SOS button if needed.',
      features: ['Verify OTP before trip start', 'Keep documents up to date', 'SOS emergency button always ready'],
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
    await prefs.setBool('driver_onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LanguageSelectScreen(),
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
                // Header row: dots + skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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

                // Pilot badge
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Text('JAGO Pilot App', style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    )),
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

                // Buttons
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
                            isLast ? 'Start Driving →' : 'Next →',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _finish,
                          child: Text('Skip to Setup',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13, fontWeight: FontWeight.w500)),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(child: Text(slide.icon, style: const TextStyle(fontSize: 58))),
            ),
            const SizedBox(height: 32),
            Text(slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 14),
            Text(slide.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.82), fontSize: 14, height: 1.6)),
            const SizedBox(height: 26),
            Column(
              children: slide.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.check, color: Colors.white, size: 14)),
                    ),
                    const SizedBox(width: 12),
                    Text(f, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
