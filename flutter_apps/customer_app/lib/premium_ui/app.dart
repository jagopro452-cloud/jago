import 'package:flutter/material.dart';
import 'theme.dart';
import 'main_home_screen.dart';
import 'booking_flow.dart';
import 'live_tracking_screen.dart';

class JagoProApp extends StatelessWidget {
  const JagoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jago Pro',
      theme: JagoTheme.themeData,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const MainHomeScreen(),
        '/booking': (_) => const BookingFlowScreen(),
        '/tracking': (_) => const LiveTrackingScreen(),
      },
    );
  }
}
