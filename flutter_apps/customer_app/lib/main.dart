import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';
import 'services/localization_service.dart';
import 'screens/booking/voice_booking_screen.dart';

// Global navigator key — used for 401 auto-logout and deep-link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> loadThemePreference() async {
  themeNotifier.value = ThemeMode.light;
}

Future<void> saveThemePreference(String pref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_pref', 'light');
  await prefs.setString('theme_mode', 'light');
  themeNotifier.value = ThemeMode.light;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemePreference();
  await L.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await Firebase.initializeApp();
    await FcmService().init();
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  } catch (_) {}
  // Forward Flutter framework errors to Crashlytics
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  // Forward async/platform errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // Catch any widget build error — show message instead of blank screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFF2F80ED), size: 48),
              const SizedBox(height: 16),
              const Text('Something went wrong.\nPlease restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0B0B0B),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
  final GlobalKey<NavigatorState> _navKey = navigatorKey;
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
        (uri.scheme == 'https' &&
            uri.host == 'jagopro.org' &&
            uri.path.startsWith('/voice-booking'));
  }

  Future<void> _openVoiceBookingIfAllowed() async {
    if (_voiceRouteOpen) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;
    final nav = _navKey.currentState;
    if (nav == null) return;
    _voiceRouteOpen = true;
    nav
        .push(MaterialPageRoute(builder: (_) => const VoiceBookingScreen()))
        .whenComplete(() {
      _voiceRouteOpen = false;
    });
  }

  Future<void> _handleIncomingUri(Uri? uri, {bool coldStart = false}) async {
    if (uri == null || !_isVoiceBookingUri(uri)) return;
    if (coldStart) {
      await Future.delayed(const Duration(milliseconds: 2000));
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
    const primary = Color(0xFF1677FF);
    const bg = Color(0xFFFFFFFF);
    const card = Color(0xFFF7FAFF);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFF5B9DFF),
        surface: card,
        background: bg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF111827),
        outline: Color(0xFFD9E4F5),
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: const Color(0xFFE5EDF7),
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: GoogleFonts.manropeTextTheme()
          .copyWith(
            headlineLarge: GoogleFonts.manrope(
                fontSize: 32, fontWeight: FontWeight.w600, height: 1.08),
            headlineMedium: GoogleFonts.manrope(
                fontSize: 28, fontWeight: FontWeight.w600, height: 1.1),
            titleLarge: GoogleFonts.manrope(
                fontSize: 20, fontWeight: FontWeight.w700, height: 1.15),
            titleMedium: GoogleFonts.manrope(
                fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
            bodyLarge: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w500, height: 1.35),
            bodyMedium: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w500, height: 1.35),
            bodySmall: GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
            labelLarge: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w700, height: 1.1),
          )
          .apply(
            bodyColor: const Color(0xFF111827),
            displayColor: const Color(0xFF111827),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827)),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5EDF7)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          textStyle:
              GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: Color(0xFFD6E6FF)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          textStyle:
              GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCE7F5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.6)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.manrope(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static ThemeData _darkTheme() {
    return _lightTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, lang, __) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, __) {
            const isDark = false;
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ));
            return MaterialApp(
              title: 'JAGO Pro',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navKey,
              themeMode: ThemeMode.light,
              theme: _lightTheme(),
              darkTheme: _lightTheme(),
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
