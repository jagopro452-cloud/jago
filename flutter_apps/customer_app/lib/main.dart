import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';
import 'services/localization_service.dart';
import 'screens/booking/voice_booking_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final pref = prefs.getString('theme_pref') ?? prefs.getString('theme_mode') ?? 'system';
  themeNotifier.value = pref == 'dark' ? ThemeMode.dark : pref == 'light' ? ThemeMode.light : ThemeMode.system;
}

Future<void> saveThemePreference(String pref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_pref', pref);
  await prefs.setString('theme_mode', pref);
  themeNotifier.value = pref == 'dark' ? ThemeMode.dark : pref == 'light' ? ThemeMode.light : ThemeMode.system;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemePreference();
  await L.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await Firebase.initializeApp();
    await FcmService().init();
  } catch (_) {}
  // Catch any widget build error — show message instead of blank screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Color(0xFF2F80ED), size: 48),
              const SizedBox(height: 16),
              const Text('Something went wrong.\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF0B0B0B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ]),
          ),
        ),
      ),
    );
  };
  runApp(const JagoCustomerApp());
}

class JagoCustomerApp extends StatefulWidget {
  const JagoCustomerApp({super.key});

  @override
  State<JagoCustomerApp> createState() => _JagoCustomerAppState();
}

class _JagoCustomerAppState extends State<JagoCustomerApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSub;
  bool _voiceRouteOpen = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  bool _isVoiceBookingUri(Uri uri) {
    final u = uri.toString().toLowerCase();
    return u.startsWith('jago://voice/booking') ||
        (uri.scheme == 'https' && uri.host == 'jagopro.org' && uri.path.startsWith('/voice-booking'));
  }

  Future<void> _openVoiceBookingIfAllowed() async {
    if (_voiceRouteOpen) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;
    final nav = _navKey.currentState;
    if (nav == null) return;
    _voiceRouteOpen = true;
    nav.push(MaterialPageRoute(builder: (_) => const VoiceBookingScreen())).whenComplete(() {
      _voiceRouteOpen = false;
    });
  }

  Future<void> _handleIncomingUri(Uri? uri, {bool coldStart = false}) async {
    if (uri == null || !_isVoiceBookingUri(uri)) return;
    if (coldStart) {
      await Future.delayed(const Duration(milliseconds: 3600));
    }
    await _openVoiceBookingIfAllowed();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialAppLink();
      await _handleIncomingUri(initial, coldStart: true);
    } catch (_) {}
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(uri);
    }, onError: (_) {});
  }

  static ThemeData _lightTheme() {
    const primary = Color(0xFF2F80ED);
    const bg = Color(0xFFFFFFFF);
    const card = Color(0xFFF5F8FF);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFF56CCF2),
        surface: card,
        background: bg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0B0B0B),
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFF0B0B0B),
        displayColor: const Color(0xFF0B0B0B),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0B0B0B)),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F8FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE9FF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
      ),
    );
  }

  static ThemeData _darkTheme() {
    const primary = Color(0xFF2F80ED);
    const bg = Color(0xFF0B0B0B);
    const card = Color(0xFF1A1A1A);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF56CCF2),
        surface: card,
        background: bg,
        onPrimary: Colors.white,
        onSurface: Colors.white,
        outline: Color(0xFF2A2A2A),
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: const Color(0xFF2A2A2A),
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, lang, __) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, __) {
            final isDark = mode == ThemeMode.dark ||
                (mode == ThemeMode.system &&
                    WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ));
            return MaterialApp(
              title: 'JAGO Pro',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navKey,
              themeMode: mode,
              theme: _lightTheme(),
              darkTheme: _darkTheme(),
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
