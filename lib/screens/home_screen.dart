import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// Commencys home: greeting header + SOS hero + quick actions.
///
/// Server icon opens backend address setting so the app works on a
/// physical phone (emulator default `10.0.2.2` only works in emulator).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            expandedHeight: 118,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingNow(),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Need help? We\'re nearby.',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ServerButton(
                      onPressed: () => _openServerDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // SOS hero
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Column(
                    children: [
                      const Pill(
                        label: 'ONE-TAP EMERGENCY',
                        bg: AppColors.accentSoft,
                        fg: AppColors.accentDeep,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/sos'),
                        child: Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.sosStart,
                                AppColors.sosEnd
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent
                                    .withValues(alpha: 0.45),
                                blurRadius: 32,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Hold the button in an emergency — your live location goes to nearby volunteers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'What do you need?'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _ActionCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Report',
                      subtitle: 'Describe an incident',
                      tint: AppColors.infoSoft,
                      iconColor: AppColors.info,
                      onTap: () =>
                          Navigator.pushNamed(context, '/report'),
                    ),
                    _ActionCard(
                      icon: Icons.map_rounded,
                      title: 'Live map',
                      subtitle: 'See what\'s nearby',
                      tint: AppColors.successSoft,
                      iconColor: AppColors.success,
                      onTap: () =>
                          Navigator.pushNamed(context, '/map'),
                    ),
                    _ActionCard(
                      icon: Icons.notifications_active_rounded,
                      title: 'Alerts',
                      subtitle: 'Updates around you',
                      tint: AppColors.warningSoft,
                      iconColor: const Color(0xFFB45309),
                      onTap: () =>
                          Navigator.pushNamed(context, '/alerts'),
                    ),
                    _ActionCard(
                      icon: Icons.sos_rounded,
                      title: 'SOS mode',
                      subtitle: 'Full-screen SOS',
                      tint: AppColors.accentSoft,
                      iconColor: AppColors.accent,
                      onTap: () =>
                          Navigator.pushNamed(context, '/sos'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const GlassCard(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.verified_outlined,
                          color: AppColors.success, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Community early-response aid — not a substitute for 112 / 119.',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
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

class _ServerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ServerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06)),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.dns_outlined,
              color: AppColors.secondary, size: 20),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.secondary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Edits the backend base URL at runtime.
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
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
