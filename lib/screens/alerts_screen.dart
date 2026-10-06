import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/volunteer_store.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_badges.dart';
import '../widgets/glass.dart';
import '../widgets/invite_cards.dart';

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
  bool _reviewOnly = false;
  List<String> _myRoles = [];
  bool _invitesOnly = false;

  @override
  void initState() {
    super.initState();
    _socket = CoordinationSocket();
    _socket.connect();
    _socket.messages.listen((msg) {
      if (!mounted) return;
      setState(() => _live = true);
      // Push-style card: when a live frame carries role targeting that
      // matches this volunteer, surface it as a special invite.
      final frameRoles = _frameRoles(msg);
      final matched = _matchRoles(frameRoles);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                matched.isNotEmpty
                    ? 'Special invite (${matched.join(', ')}): '
                        '${msg['title'] ?? 'new alert'}'
                    : 'Live update: ${msg['title'] ?? 'new alert'}')),
      );
      _load(silent: true);
    });
    _loadRoles();
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

  Future<void> _loadRoles() async {
    final roles = await VolunteerStore.roles();
    if (mounted) setState(() => _myRoles = roles);
  }

  List<String> _matchRoles(List<String> requiredRoles) {
    final mine = _myRoles.map((r) => r.toLowerCase()).toSet();
    return requiredRoles
        .where((r) => mine.contains(r.toLowerCase()))
        .toList();
  }

  /// `required_roles` attached to a live WS frame (nested or top-level).
  static List<String> _frameRoles(Map<String, dynamic> msg) {
    for (final key in ['required_roles', 'requiredRoles']) {
      final v = msg[key];
      if (v is List) return v.map((e) => e.toString()).toList();
    }
    final incident = msg['incident'];
    if (incident is Map<String, dynamic>) {
      final v = incident['required_roles'];
      if (v is List) return v.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<void> _openCoordinator(Incident incident) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CoordinatorActionsSheet(
        incident: incident,
        onCorrect: ({category, urgency}) async {
          try {
            await _api.correctTicket(
              ticketId: incident.id,
              aiCategory: category ?? incident.aiCategory,
              urgency: urgency,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Correction saved — raw report kept.')),
              );
              _load(silent: true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Correction failed: $e')),
              );
            }
          }
        },
        onSplit: () async {
          try {
            await _api.splitCluster(ticketId: incident.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cluster link cleared.')),
              );
              _load(silent: true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Split failed: $e')),
              );
            }
          }
        },
      ),
    );
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
    final reviewCount = _incidents.where((e) => e.needsReview).length;
    var visible = _reviewOnly
        ? _incidents.where((e) => e.needsReview).toList()
        : List<Incident>.from(_incidents);
    // Special invites first, then the rest (normal incidents read dimmed).
    final matchedOf = <String, List<String>>{};
    for (final e in visible) {
      matchedOf[e.id] = _matchRoles(e.requiredRoles);
    }
    final inviteCount =
        matchedOf.values.where((m) => m.isNotEmpty).length;
    if (_invitesOnly) {
      visible = visible
          .where((e) => matchedOf[e.id]?.isNotEmpty == true)
          .toList();
    } else {
      visible.sort((a, b) {
        final am = matchedOf[a.id]?.isNotEmpty == true ? 0 : 1;
        final bm = matchedOf[b.id]?.isNotEmpty == true ? 0 : 1;
        if (am != bm) return am - bm;
        return b.createdAt.compareTo(a.createdAt);
      });
    }
    final headerCards = (reviewCount > 0 ? 1 : 0) +
        (inviteCount > 0 && _myRoles.isNotEmpty ? 1 : 0);
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
                    itemCount: visible.length + headerCards,
                    itemBuilder: (context, i) {
                      var h = i;
                      if (inviteCount > 0 && _myRoles.isNotEmpty) {
                        if (h == 0) {
                          return SpecialInviteBanner(
                            count: inviteCount,
                            onTap: () => setState(() =>
                                _invitesOnly = !_invitesOnly),
                          );
                        }
                        h -= 1;
                      }
                      if (reviewCount > 0 && h == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LiquidGlass(
                            radius: 20,
                            blur: 24,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            onTap: () => setState(
                                () => _reviewOnly = !_reviewOnly),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.rate_review_outlined,
                                  size: 18,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Needs review ($reviewCount)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Pill(
                                  label:
                                      _reviewOnly ? 'SHOWING' : 'FILTER',
                                  bg: AppColors.warningSoft,
                                  fg: const Color(0xFFB45309),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final idx = reviewCount > 0 ? h - 1 : h;
                      final incident = visible[idx];
                      final matched = matchedOf[incident.id] ?? const [];
                      final invited = matched.isNotEmpty;
                      final sev =
                          AppColors.severityFor(incident.severity.name);
                      final sevSoft = AppColors.severitySoftFor(
                          incident.severity.name);
                      final last = idx == visible.length - 1;
                      // Normal incidents read dimmed when the user has
                      // special invites waiting — the eye goes to the call.
                      final card = LiquidGlass(
                        radius: 22,
                        blur: 26,
                        tint: invited ? 1.0 : 0.72,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (invited) ...[
                                    SpecialInviteBadge(
                                      matched: matched,
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  Text(
                                    incident.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: invited
                                          ? AppColors.ink
                                          : AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${incident.category} • ${incident.status.name} • ${DateFormat('dd MMM HH:mm').format(incident.createdAt)}',
                                    style: const TextStyle(
                                      color:
                                          AppColors.secondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  if (invited) ...[
                                    const SizedBox(height: 8),
                                    InviteWhyLine(
                                      incident: incident,
                                      matched: matched,
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  AiTriageBadges(
                                    incident: incident,
                                    onClusterTap: () =>
                                        _openCoordinator(
                                            incident),
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
                      );
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
                                child: invited
                                    ? Container(
                                        decoration:
                                            BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  22),
                                          border: Border.all(
                                            color: AppColors.accent
                                                .withValues(
                                                    alpha: 0.55),
                                            width: 1.4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withValues(
                                                      alpha:
                                                          0.18),
                                              blurRadius: 18,
                                              offset: const Offset(
                                                  0, 6),
                                            ),
                                          ],
                                        ),
                                        child: card,
                                      )
                                    : Opacity(
                                        opacity: 0.62,
                                        child: card,
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
