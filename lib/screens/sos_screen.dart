import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/type_sos_widget.dart';
import '../widgets/voice_sos_widget.dart';

/// SOS tab: voice SOS + type SOS, side by side.
///
/// One-tap SOS was removed — every SOS now carries context (a voice clip
/// or a typed note) + GPS so Laya can triage. Transports are unchanged:
/// [ApiClient.sendSosVoice] (voice) and [ApiClient.sendSos] (typed note).
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          children: [
            Pill(
              label: 'P1 · Segera / NOW — until triage',
              bg: AppColors.accentSoft,
              fg: AppColors.accentDeep,
              icon: Icons.shield_outlined,
            ),
            SizedBox(height: 16),
            VoiceSosWidget(),
            SizedBox(height: 12),
            TypeSosWidget(),
            SizedBox(height: 16),
            GlassCard(
              padding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.secondary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Community early-response aid — not a substitute for emergency services 112 / 119.',
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
          ],
        ),
      ),
    );
  }
}
