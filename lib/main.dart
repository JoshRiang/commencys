import 'package:flutter/material.dart';

import 'screens/alerts_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/sos_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CommencysApp());
}

class CommencysApp extends StatelessWidget {
  const CommencysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Commencys',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/sos': (context) => const SosScreen(),
        '/report': (context) => const ReportScreen(),
        '/map': (context) => const MapScreen(),
        '/alerts': (context) => const AlertsScreen(),
      },
    );
  }
}
