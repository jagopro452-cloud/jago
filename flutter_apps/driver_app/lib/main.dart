import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const JagoPilotApp());
}

class JagoPilotApp extends StatelessWidget {
  const JagoPilotApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JAGO Pilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), brightness: Brightness.dark),
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFF060D1E),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF060D1E),
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
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
