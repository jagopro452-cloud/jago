import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const JagoApp());
}

class JagoApp extends StatelessWidget {
  const JagoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JAGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6DE5)),
        primaryColor: const Color(0xFF1E6DE5),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(color: Color(0xFF1A1A2E), fontSize: 17, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E6DE5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    );
  }
}
