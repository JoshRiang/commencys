import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_badges.dart';
import '../widgets/glass.dart';
import '../widgets/status_timeline.dart';

/// One-tap SOS: GPS auto-attach (+accuracy radius), stored+acked by the
/// backend in < 5 s, with transparent ticket status (acknowledged ≠
/// dispatched). The red gradient hero keeps its identity inside a
/// Liquid Glass surround. API unchanged: [ApiClient.sendSos].
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _api = ApiClient();
  final _location = LocationService();
  bool _sending = false;
  String _status = 'Press SOS to send your live location.';
  Incident? _ticket;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _sendSos() async {
    setState(() {
      _sending = true;
      _status = 'Getting your location...';
      _ticket = null;
    });
    try {
      final pos = await _location.currentPosition();
      if (pos == null) {
        setState(() => _status = 'Location permission denied. Enable GPS.');
        return;
      }
      setState(() => _status = 'Sending SOS...');
      // GPS + accuracy radius; the live pin is visible on the map tab.
      final ticket = await _api.sendSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyM: pos.accuracy,
        reporterName: 'App User',
      );
      setState(() {
        _ticket = ticket;
        _status = 'SOS received by system (id ${ticket.id}).';
      });
    } catch (e) {
      setState(() => _status = 'Failed to send SOS: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          children: [
            const Pill(
              label: 'FAIL-SAFE P1 UNTIL TRIAGE',
              bg: AppColors.accentSoft,
              fg: AppColors.accentDeep,
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: 16),
            LiquidGlass(
              radius: 28,
              blur: 28,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  GestureDetector(
                    onLongPress: _sending ? null : _sendSos,
                    onTap: _sending ? null : _sendSos,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 216,
                      height: 216,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _sending
                              ? [
                                  Colors.grey.shade400,
                                  Colors.grey.shade500
                                ]
                              : const [
                                  AppColors.sosStart,
                                  AppColors.sosEnd
                                ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_sending
                                    ? Colors.grey
                                    : AppColors.accent)
                                .withValues(alpha: 0.45),
                            blurRadius: 36,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _sending
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 60,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'TAP TO SEND',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (ticket != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ticket ${ticket.id}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Pill(
                          label:
                              'URG ${ticket.urgency.name.toUpperCase()}',
                          bg: AppColors.accentSoft,
                          fg: AppColors.accentDeep,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Triage pending — volunteers nearby will be notified.',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AiTriageBadges(incident: ticket),
                    if (ticket.accuracyM != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'GPS ±${ticket.accuracyM!.toStringAsFixed(0)} m · '
                            '${ticket.latitude.toStringAsFixed(5)}, '
                            '${ticket.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    StatusTimeline(status: ticket.status),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/map'),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('View map'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/alerts'),
                      icon: const Icon(
                          Icons.notifications_outlined,
                          size: 18),
                      label: const Text('View alerts'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const GlassCard(
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
