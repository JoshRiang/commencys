import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// Global navigator key so a P1 invite can surface a full-screen alert from
/// anywhere (including a WS callback with no BuildContext).
class AppNav {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

/// How a live WS frame should surface, decided from invite targeting +
/// urgency. Pure data — see [InviteRouting.decide] (unit-tested).
enum AlertAction { emergency, invite, broadcast, silent }

/// Parsed routing decision for one live frame.
class InviteDecision {
  final AlertAction action;
  final String incidentId;
  final String title;
  final String urgency;
  final String category;
  final List<String> matchedRoles;
  final String? reason;

  const InviteDecision({
    required this.action,
    required this.incidentId,
    required this.title,
    required this.urgency,
    required this.category,
    required this.matchedRoles,
    this.reason,
  });
}

/// Pure routing: P1 + role-match → full-screen emergency; role-match →
/// normal invite; untargeted P1/critical → normal broadcast; else silent.
///
/// Mirrors the contract: frames carry `urgency: "P1"…` and tickets carry
/// `required_roles` (docs/api-contract.md, ticket object + WS frames).
class InviteRouting {
  static const _emergencyTypes = {
    'incident.sos',
    'incident.dispatch_auto',
    'incident.dispatched',
  };

  static InviteDecision decide(
    Map<String, dynamic> msg,
    List<String> myRoles,
  ) {
    final m = msg['incident'] is Map<String, dynamic>
        ? {...msg, ...msg['incident'] as Map<String, dynamic>}
        : msg;
    final type = (msg['type'] ?? m['type'])?.toString() ?? '';
    final urgency =
        (m['urgency'] ?? msg['urgency'])?.toString().toUpperCase() ?? '';
    final severity = (m['severity'] ?? msg['severity'])?.toString() ?? '';
    final id = (m['id'] ?? msg['id'])?.toString() ?? '';
    final title =
        (m['title'] ?? msg['title'])?.toString() ?? 'New emergency alert';
    final category =
        (m['category'] ?? msg['category'])?.toString() ?? 'sos';
    final reason = (m['reason'] ?? m['invite_reason'])?.toString();

    final required = _roleList(m['required_roles'] ?? msg['required_roles']);
    final mine = myRoles.map((r) => r.toLowerCase()).toSet();
    final matched =
        required.where((r) => mine.contains(r.toLowerCase())).toList();

    final isP1 = urgency == 'P1';
    final isCriticalCall =
        _emergencyTypes.contains(type) && severity == 'critical';

    if (matched.isNotEmpty && (isP1 || isCriticalCall)) {
      return InviteDecision(
        action: AlertAction.emergency,
        incidentId: id,
        title: title,
        urgency: urgency.isEmpty ? 'P1' : urgency,
        category: category,
        matchedRoles: matched,
        reason: reason,
      );
    }
    if (matched.isNotEmpty) {
      return InviteDecision(
        action: AlertAction.invite,
        incidentId: id,
        title: title,
        urgency: urgency,
        category: category,
        matchedRoles: matched,
        reason: reason,
      );
    }
    if (isP1 || severity == 'critical') {
      return InviteDecision(
        action: AlertAction.broadcast,
        incidentId: id,
        title: title,
        urgency: urgency,
        category: category,
        matchedRoles: const [],
        reason: reason,
      );
    }
    return InviteDecision(
      action: AlertAction.silent,
      incidentId: id,
      title: title,
      urgency: urgency,
      category: category,
      matchedRoles: const [],
    );
  }

  static List<String> _roleList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) {
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }
}

/// System alert surface for invites.
///
/// - P1 + invited (see [InviteRouting]): full-screen intent notification on
///   the emergency channel (max importance, alarm category, insistent sound),
///   an emergency vibration pattern, and in-app navigation to the full-screen
///   [P1InviteScreen] when the app is in the foreground.
/// - Anything else: a normal notification on the default channel (or nothing),
///   default sound, no vibration pattern — escalating urgency honestly instead
///   of startling people for routine broadcasts.
class InviteAlertService {
  InviteAlertService._();

  static final InviteAlertService instance = InviteAlertService._();

  static const emergencyChannelId = 'p1_invites';
  static const normalChannelId = 'alerts';
  static const _emergencyNotificationId = 911001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Latest emergency invite, read by the full-screen route.
  InviteDecision? pendingInvite;

  String? _lastEmergencyKey;
  DateTime? _lastEmergencyAt;

  Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              emergencyChannelId,
              'Emergency invites',
              description:
                  'P1 incidents that request your role. Full-screen alert with alarm sound.',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              normalChannelId,
              'Incident alerts',
              description: 'Routine incident broadcasts.',
              importance: Importance.high,
            ),
          );
    } catch (_) {
      // Notifications are best-effort; the in-app surface still works.
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.startsWith('p1:') && pendingInvite != null) {
      AppNav.key.currentState?.pushNamed('/p1-invite');
    } else if (payload.startsWith('alert:')) {
      AppNav.key.currentState?.pushNamed('/alerts');
    }
  }

  /// Route one live WS frame. Returns the decision so callers can pair the
  /// system surface with a matching in-app treatment.
  Future<InviteDecision> handleLiveFrame(
    Map<String, dynamic> msg,
    List<String> myRoles,
  ) async {
    final decision = InviteRouting.decide(msg, myRoles);
    switch (decision.action) {
      case AlertAction.emergency:
        await raiseEmergency(decision);
      case AlertAction.invite:
        await showInvite(decision);
      case AlertAction.broadcast:
        await showBroadcast(decision.title, _bodyFor(decision),
            id: decision.incidentId);
      case AlertAction.silent:
        break;
    }
    return decision;
  }

  static String _bodyFor(InviteDecision d) {
    final role = d.matchedRoles.isEmpty
        ? ''
        : 'Needs ${d.matchedRoles.join(', ')}. ';
    final reason = d.reason == null || d.reason!.isEmpty ? '' : d.reason!;
    return '$role$reason'.trim().isEmpty
        ? '${d.category} • ${d.urgency}'
        : ('$role$reason'.trim() + ' (${d.category} • ${d.urgency})');
  }

  /// P1 + invited: full-screen intent, insistent alarm sound, emergency
  /// vibration, and immediate in-app navigation when possible.
  Future<void> raiseEmergency(InviteDecision decision) async {
    // One alert per incident (no repeat buzz for the same call).
    final key = decision.incidentId;
    final now = DateTime.now();
    if (key.isNotEmpty &&
        key == _lastEmergencyKey &&
        _lastEmergencyAt != null &&
        now.difference(_lastEmergencyAt!) < const Duration(minutes: 2)) {
      return;
    }
    _lastEmergencyKey = key;
    _lastEmergencyAt = now;
    pendingInvite = decision;

    await _plugin.show(
      _emergencyNotificationId,
      'P1 INVITE — ${decision.title}',
      _bodyFor(decision),
      NotificationDetails(
        android: AndroidNotificationDetails(
          emergencyChannelId,
          'Emergency invites',
          channelDescription:
              'P1 incidents that request your role. Full-screen alert with alarm sound.',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          // Full-screen intent: turns the screen on with the alert even
          // when the phone is locked (needs USE_FULL_SCREEN_INTENT).
          fullScreenIntent: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(
            const [0, 600, 250, 600, 250, 900],
          ),
          // FLAG_INSISTENT: alarm repeats until the volunteer acts.
          // Cleared in [dismissEmergency] when the alert opens / is answered.
          additionalFlags: Int32List.fromList(<int>[4]),
          ticker: 'Emergency invite — your role is needed',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'p1:${decision.incidentId}',
    );

    // Companion in-app haptic: sound + vibration together, never alone.
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: const [0, 600, 250, 600, 250, 900],
        );
      }
    } catch (_) {
      // Devices without a vibrator still get sound + full-screen UI.
    }

    // Foreground: go straight to the full-screen alert route.
    final nav = AppNav.key.currentState;
    if (nav != null) {
      scheduleMicrotask(() => nav.pushNamed('/p1-invite'));
    }
  }

  /// Invited but not P1: normal heads-up, default sound, no vibration
  /// pattern, no full-screen intent.
  Future<void> showInvite(InviteDecision decision) async {
    await _plugin.show(
      _idFor(decision.incidentId),
      'Special invite — ${decision.title}',
      _bodyFor(decision),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          normalChannelId,
          'Incident alerts',
          importance: Importance.high,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'alert:${decision.incidentId}',
    );
  }

  /// Untargeted P1/critical: normal broadcast notification.
  Future<void> showBroadcast(String title, String body, {String? id}) async {
    await _plugin.show(
      _idFor(id ?? title),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          normalChannelId,
          'Incident alerts',
          importance: Importance.high,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'alert:${id ?? ''}',
    );
  }

  /// Stop the insistent alarm + vibration once the volunteer sees the alert.
  Future<void> dismissEmergency() async {
    try {
      await _plugin.cancel(_emergencyNotificationId);
    } catch (_) {}
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  int _idFor(String seed) => 100000 + (seed.hashCode.abs() % 800000);
}
