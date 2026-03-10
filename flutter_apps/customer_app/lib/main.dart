import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final mode = prefs.getString('theme_mode') ?? 'system';
  themeNotifier.value = mode == 'light'
      ? ThemeMode.light
      : mode == 'dark'
          ? ThemeMode.dark
          : ThemeMode.system;
}

Future<void> saveThemePreference(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  final val = mode == ThemeMode.light
      ? 'light'
      : mode == ThemeMode.dark
          ? 'dark'
          : 'system';
  await prefs.setString('theme_mode', val);
  themeNotifier.value = mode;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await loadThemePreference();
  await L.init();
  try {
    await Firebase.initializeApp();
    await FcmService().init();
  } catch (_) {}
  runApp(const JagoApp());
}

class JagoApp extends StatefulWidget {
  const JagoApp({super.key});

  @override
  State<JagoApp> createState() => _JagoAppState();
}

class _JagoAppState extends State<JagoApp> {
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
                    WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                        Brightness.dark);
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ));
            return MaterialApp(
              title: 'JAGO',
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

  ThemeData _lightTheme() => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E6DE5),
          primary: const Color(0xFF1E6DE5),
          secondary: const Color(0xFFFFD700),
          surface: Colors.white,
        ),
        primaryColor: const Color(0xFF1E6DE5),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Roboto',
        cardColor: Colors.white,
        dividerColor: const Color(0xFFEEEEEE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: Color(0xFF111827)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E6DE5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF111827)),
          bodyMedium: TextStyle(color: Color(0xFF374151)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
        ),
        useMaterial3: true,
      );

  ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E6DE5),
            primary: const Color(0xFF1E6DE5),
            secondary: const Color(0xFFFFD700),
            surface: const Color(0xFF0D1B3E),
            brightness: Brightness.dark),
        primaryColor: const Color(0xFF1E6DE5),
        scaffoldBackgroundColor: const Color(0xFF060D1E),
        fontFamily: 'Roboto',
        cardColor: const Color(0xFF0D1B3E),
        dividerColor: Colors.white10,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1B3E),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E6DE5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1B3E),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFFE5E7EB)),
          bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        useMaterial3: true,
      );
}
