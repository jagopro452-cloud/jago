import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';

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
  // Firebase init (requires google-services.json + GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
    await FcmService().init();
  } catch (_) {
    // Firebase not configured yet — add google-services.json to enable push notifications
  }
  runApp(const JagoApp());
}

class JagoApp extends StatelessWidget {
  const JagoApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          themeMode: mode,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeData _lightTheme() => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6DE5)),
        primaryColor: const Color(0xFF1E6DE5),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        cardColor: Colors.white,
        dividerColor: const Color(0xFFEEEEEE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 17,
              fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
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
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        useMaterial3: false,
      );

  ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E6DE5),
            brightness: Brightness.dark),
        primaryColor: const Color(0xFF1E6DE5),
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        fontFamily: 'Roboto',
        cardColor: const Color(0xFF141B2D),
        dividerColor: Colors.white12,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0F1E),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
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
          fillColor: const Color(0xFF141B2D),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        useMaterial3: false,
      );
}
