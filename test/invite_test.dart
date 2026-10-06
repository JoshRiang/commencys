import 'package:commencys/models/incident.dart';
import 'package:commencys/models/volunteer.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident(List<String> requiredRoles, {String? reason}) {
  return Incident(
    id: 't1',
    title: 'Building fire',
    description: 'Smoke on floor 2',
    category: 'fire',
    latitude: -6.2,
    longitude: 106.8,
    severity: IncidentSeverity.critical,
    status: IncidentStatus.broadcast,
    createdAt: DateTime.utc(2026, 10, 6),
    reporterName: 'Tester',
    requiredRoles: requiredRoles,
    inviteReason: reason,
  );
}

void main() {
  group('Targeted invites', () {
    test('required_roles + reason parse from JSON', () {
      final restored = Incident.fromJson({
        'id': 't1',
        'title': 'Fire',
        'description': 'Kitchen fire',
        'category': 'fire',
        'latitude': -6.2,
        'longitude': 106.8,
        'severity': 'critical',
        'status': 'broadcast',
        'created_at': '2026-10-06T00:00:00Z',
        'reporter_name': 'Tester',
        'required_roles': ['fire', 'medical'],
        'reason': 'Nearest crew with breathing apparatus',
      });
      expect(restored.requiredRoles, ['fire', 'medical']);
      expect(
        restored.inviteReason,
        'Nearest crew with breathing apparatus',
      );
    });

    test('missing targeting defaults to empty (normal broadcast)', () {
      final restored = Incident.fromJson({
        'id': 't2',
        'title': 'Pothole',
        'description': 'Road damage',
        'category': 'facility',
        'latitude': -6.2,
        'longitude': 106.8,
        'severity': 'low',
        'status': 'broadcast',
        'created_at': '2026-10-06T00:00:00Z',
        'reporter_name': 'Tester',
      });
      expect(restored.requiredRoles, isEmpty);
      expect(restored.inviteReason, isNull);
      expect(restored.isSpecialInviteFor(['medical']), isFalse);
    });

    test('intersection is case-insensitive', () {
      final incident = _incident(['Fire', 'MEDICAL']);
      expect(
        incident.matchedRoles(['medical', 'driver']),
        ['MEDICAL'],
      );
      expect(incident.isSpecialInviteFor(['driver']), isFalse);
      expect(
        incident.isSpecialInviteFor(['driver', 'fire']),
        isTrue,
      );
    });

    test('round-trip keeps invite metadata', () {
      final incident =
          _incident(['rescue'], reason: 'Swift-water team needed');
      final restored = Incident.fromJson(incident.toJson());
      expect(restored.requiredRoles, ['rescue']);
      expect(restored.inviteReason, 'Swift-water team needed');
    });
  });

  group('Volunteer', () {
    test('role ids are server-canonical', () {
      expect(
        Volunteer.allRoles,
        ['medical', 'fire', 'rescue', 'security', 'driver', 'coordinator'],
      );
    });

    test('registration payload shape', () {
      const v = Volunteer(
        name: 'Andi',
        roles: ['medical', 'driver'],
        skills: ['CPR'],
        latitude: -6.2,
        longitude: 106.8,
      );
      final json = v.toJson();
      expect(json['name'], 'Andi');
      expect(json['roles'], ['medical', 'driver']);
      expect(json['skills'], ['CPR']);
      expect(json['latitude'], -6.2);
      expect(json['longitude'], 106.8);
      expect(Volunteer.fromJson(json).roles, ['medical', 'driver']);
    });

    test('matchedRoles helper mirrors incident matching', () {
      const v = Volunteer(name: 'Budi', roles: ['Fire']);
      expect(v.matchedRoles(['fire', 'medical']), ['fire']);
      expect(v.isInvitedBy(['security']), isFalse);
    });
  });
}
