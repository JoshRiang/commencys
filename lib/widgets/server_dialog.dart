import 'package:flutter/material.dart';

import '../services/app_config.dart';

/// Runtime backend URL editor, reachable from Home and the Map top bar.
///
/// Emulator default `10.0.2.2` only works in the emulator — on a physical
/// phone enter the backend host on the LAN, e.g. `http://192.168.1.10:8000`.
/// A compile-time default can also be baked in:
/// `flutter build apk --dart-define=API_BASE=http://192.168.1.10:8000`.
class ServerDialog extends StatefulWidget {
  const ServerDialog({super.key});

  @override
  State<ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<ServerDialog> {
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      title: const Text('Backend server',
          style: TextStyle(fontWeight: FontWeight.w800)),
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
                    !(uri.scheme == 'http' ||
                        uri.scheme == 'https') ||
                    uri.host.isEmpty) {
                  return 'Use http(s)://host:port';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Emulator default: http://10.0.2.2:8000. '
              'On a physical phone use the backend host on your LAN.',
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

/// Opens the backend server dialog.
Future<void> showServerDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const ServerDialog(),
  );
}
