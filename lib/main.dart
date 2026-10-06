import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'screens/role_picker_screen.dart';
import 'services/volunteer_store.dart';
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
      // First launch lands on the role picker; afterwards the map shell.
      home: const _LaunchGate(),
      routes: {
        '/roles': (context) => const RolePickerScreen(editing: true),
        '/sos': (context) => const AppShell(initialTab: 4),
        '/report': (context) => const AppShell(initialTab: 1),
        '/map': (context) => const AppShell(initialTab: 2),
        '/alerts': (context) => const AppShell(initialTab: 3),
      },
    );
  }
}

/// First-launch gate: volunteers without a stored role profile see the
/// "What is your role?" picker before the map shell.
class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    VolunteerStore.isOnboarded().then((v) {
      if (mounted) setState(() => _onboarded = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = _onboarded;
    if (onboarded == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (onboarded) return const AppShell();
    return RolePickerScreen(
      key: const ValueKey('onboarding'),
      onSaved: () => setState(() => _onboarded = true),
    );
  }
}
