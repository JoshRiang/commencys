import 'package:flutter/material.dart';

import '../services/app_config.dart';

/// Commencys home: big SOS entry + navigation tiles.
///
/// The server icon in the app bar opens the backend address setting, so the
/// app works on a physical phone (the emulator default `10.0.2.2` only works
/// inside the Android emulator). The address applies to every screen opened
/// afterwards.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commencys'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.dns),
            tooltip: 'Backend server',
            onPressed: () => _openServerDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Emergency? Tap SOS now.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/sos'),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _MenuTile(
                icon: Icons.report,
                label: 'Report Incident',
                onTap: () => Navigator.pushNamed(context, '/report'),
              ),
              _MenuTile(
                icon: Icons.map,
                label: 'Live Map',
                onTap: () => Navigator.pushNamed(context, '/map'),
              ),
              _MenuTile(
                icon: Icons.notifications_active,
                label: 'Alerts',
                onTap: () => Navigator.pushNamed(context, '/alerts'),
              ),
              _MenuTile(
                icon: Icons.sos,
                label: 'SOS Mode',
                onTap: () => Navigator.pushNamed(context, '/sos'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openServerDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const _ServerDialog(),
    );
  }
}

/// Edits the backend base URL at runtime (persisted for this session).
class _ServerDialog extends StatefulWidget {
  const _ServerDialog();

  @override
  State<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<_ServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backend server'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://192.168.1.10:8000',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Required';
                final uri = Uri.tryParse(value);
                if (uri == null ||
                    !(uri.scheme == 'http' || uri.scheme == 'https') ||
                    uri.host.isEmpty) {
                  return 'Use http(s)://host:port';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Emulator default: http://10.0.2.2:8000. '
              'On a physical phone use the backend host on your LAN. '
              'Applies to screens opened after saving.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            AppConfig.setBaseUrl(_ctrl.text);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Server: ${AppConfig.baseUrl}')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.red.shade700),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
