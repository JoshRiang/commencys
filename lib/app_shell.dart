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
    // layout.md › Guides and safe areas: non-map tabs reserve the bar's
    // own clearance plus the system bottom inset (SafeArea alone only
    // covers the inset, not the floating bar). The map tab handles its
    // own clearance internally so the map stays full-bleed.
    final bottomPad = kFloatingTabBarClearance +
        MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: const HomeScreen(),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: ReportScreen(onSubmitted: () => _go(3)),
          ),
          MapScreen(onSosPressed: () => _go(4)),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: const AlertsScreen(),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: const SosScreen(),
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
