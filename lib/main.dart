import 'package:flutter/material.dart';

import 'app_shell.dart';
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
      // Map-centric shell: the live map is the default home (center tab).
      home: const AppShell(),
      routes: {
        '/sos': (context) => const AppShell(initialTab: 4),
        '/report': (context) => const AppShell(initialTab: 1),
        '/map': (context) => const AppShell(initialTab: 2),
        '/alerts': (context) => const AppShell(initialTab: 3),
      },
    );
  }
}
