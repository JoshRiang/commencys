import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/report_screen.dart';
import 'screens/map_screen.dart';
import 'screens/alerts_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
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
