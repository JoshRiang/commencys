import 'package:flutter/material.dart';

import 'screens/alerts_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/sos_screen.dart';
import 'widgets/floating_tab_bar.dart';

/// Map-centric app shell: the live map is the default home (center tab),
/// floating above it a Liquid Glass tab bar. Non-map tabs get bottom
/// clearance so content never hides behind the floating bar.
class AppShell extends StatefulWidget {
  final int initialTab;

  const AppShell({super.key, this.initialTab = 2});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Map is the home screen.
  late int _index = widget.initialTab;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 96),
            child: HomeScreen(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: ReportScreen(onSubmitted: () => _go(3)),
          ),
          MapScreen(onSosPressed: () => _go(4)),
          const Padding(
            padding: EdgeInsets.only(bottom: 96),
            child: AlertsScreen(),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 96),
            child: SosScreen(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: FloatingGlassTabBar(
            currentIndex: _index,
            onTap: _go,
          ),
        ),
      ),
    );
  }
}
