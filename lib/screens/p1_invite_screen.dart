import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/invite_alerts.dart';
import '../services/volunteer_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// Full-screen P1 invite alert.
///
/// Shown when a P1 incident specially invites this volunteer
/// (see [InviteRouting.decide]). One call to action — **Respond** — which
/// dispatches the volunteer via the API, plus a safe **Dismiss** that only
/// silences the insistent alarm (the ticket stays visible in Alerts).
class P1InviteScreen extends StatefulWidget {
  const P1InviteScreen({super.key});

  @override
  State<P1InviteScreen> createState() => _P1InviteScreenState();
}

class _P1InviteScreenState extends State<P1InviteScreen> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Stop the repeating alarm as soon as the alert is on screen; the
    // vibration pattern already fired. Urgent, not endless.
    InviteAlertService.instance.dismissEmergency();
  }

  Future<void> _respond(InviteDecision invite) async {
    if (_sending) return;
    setState(() => _sending = true);
    HapticFeedback.heavyImpact();
    try {
      final me = await VolunteerStore.load();
      final name = (me?.name ?? '').trim();
      await ApiClient().dispatch(
        ticketId: invite.incidentId,
        volunteer: name.isEmpty ? 'volunteer' : name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responding — dispatch recorded. Stay safe.'),
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispatch failed: $e')),
      );
    }
  }

  void _dismiss() {
    HapticFeedback.selectionClick();
    InviteAlertService.instance.dismissEmergency();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final invite = InviteAlertService.instance.pendingInvite;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.accentDeep,
      body: SafeArea(
        child: Semantics(
          label: 'P1 emergency invite alert',
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.emergency_share_rounded,
                      color: Colors.white,
                      size: 30,
                      semanticLabel: 'Emergency',
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'P1 INVITE — YOUR ROLE IS NEEDED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LiquidGlass(
                    radius: 28,
                    blur: 30,
                    padding: const EdgeInsets.all(22),
                    child: invite == null
                        ? const Center(
                            child: Text(
                              'This invite was already handled. '
                              'Check Alerts for the latest status.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, height: 1.5),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invite.title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Pill(
                                      label: invite.urgency.isEmpty
                                          ? 'P1'
                                          : invite.urgency,
                                      bg: AppColors.accentSoft,
                                      fg: AppColors.accentDeep,
                                    ),
                                    Pill(
                                      label: invite.category.toUpperCase(),
                                      bg: AppColors.infoSoft,
                                      fg: AppColors.info,
                                    ),
                                    for (final r in invite.matchedRoles)
                                      Pill(
                                        label:
                                            'YOU: ${r.toUpperCase()}',
                                        bg: AppColors.successSoft,
                                        fg: AppColors.success,
                                      ),
                                  ],
                                ),
                                if (invite.reason != null &&
                                    invite.reason!.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    invite.reason!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                const Text(
                                  'Tap Respond to accept this call and record '
                                  'your dispatch. Only respond if you can '
                                  'help right now.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _sending || invite == null
                        ? null
                        : () => _respond(invite),
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.volunteer_activism_rounded),
                    label: Text(
                      _sending ? 'Recording…' : 'Respond — I Can Help',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accentDeep,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: _dismiss,
                    child: const Text(
                      'Dismiss (stays in Alerts)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
