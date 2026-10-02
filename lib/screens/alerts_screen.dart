import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// Alerts as a glass timeline list over a soft gradient backdrop.
/// Live frames arrive on [CoordinationSocket.messages] (`/ws/alerts`);
/// list data from [ApiClient.fetchIncidents] — both unchanged.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _api = ApiClient();
  late final CoordinationSocket _socket;
  List<Incident> _incidents = [];
  bool _loading = true;
  bool _live = false;

  @override
  void initState() {
    super.initState();
    _socket = CoordinationSocket();
    _socket.connect();
    _socket.messages.listen((msg) {
      if (!mounted) return;
      setState(() => _live = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Live update: ${msg['title'] ?? 'new alert'}')),
      );
      _load(silent: true);
    });
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final incidents = await _api.fetchIncidents();
      if (mounted) setState(() => _incidents = incidents);
    } catch (_) {
      // Keep existing list on error.
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _api.dispose();
    _socket.dispose();
    super.dispose();
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'medical':
        return Icons.medical_services_outlined;
      case 'accident':
        return Icons.car_crash_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      case 'security':
        return Icons.shield_outlined;
      case 'facility':
        return Icons.business_outlined;
      case 'sos':
        return Icons.sos_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Pill(
              label: _live ? 'LIVE' : 'SYNCING',
              bg: _live
                  ? AppColors.successSoft
                  : AppColors.warningSoft,
              fg: _live
                  ? AppColors.success
                  : const Color(0xFFB45309),
              icon: _live
                  ? Icons.bolt_rounded
                  : Icons.sync_rounded,
            ),
          ),
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'You\'re all caught up',
                    hint:
                        'New incidents near you will land here in real time.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(silent: true),
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _incidents.length,
                    itemBuilder: (context, i) {
                      final incident = _incidents[i];
                      final sev =
                          AppColors.severityFor(incident.severity.name);
                      final sevSoft = AppColors.severitySoftFor(
                          incident.severity.name);
                      final last = i == _incidents.length - 1;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: sevSoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: sev, width: 1.5),
                                  ),
                                  child: Icon(
                                    _categoryIcon(
                                        incident.category),
                                    color: sev,
                                    size: 15,
                                  ),
                                ),
                                if (!last)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      margin:
                                          const EdgeInsets.symmetric(
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                            alpha: 0.10),
                                        borderRadius:
                                            BorderRadius.circular(
                                                2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: last ? 0 : 10),
                                child: LiquidGlass(
                                  radius: 22,
                                  blur: 26,
                                  padding:
                                      const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              incident.title,
                                              style:
                                                  const TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: 3),
                                            Text(
                                              '${incident.category} • ${incident.status.name} • ${DateFormat('dd MMM HH:mm').format(incident.createdAt)}',
                                              style:
                                                  const TextStyle(
                                                color: AppColors
                                                    .secondary,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Pill(
                                        label: incident.severity.name
                                            .toUpperCase(),
                                        bg: sevSoft,
                                        fg: sev,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
