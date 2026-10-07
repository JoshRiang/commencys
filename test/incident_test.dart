import 'package:commencys/models/incident.dart';
import 'package:commencys/services/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('wsUrlFor maps http(s) base to ws(s) alerts endpoint', () {
      expect(
        AppConfig.wsUrlFor('http://10.0.2.2:8000'),
        'ws://10.0.2.2:8000/ws/alerts',
      );
      expect(
        AppConfig.wsUrlFor('https://example.com:8443/'),
        'wss://example.com:8443/ws/alerts',
      );
      expect(
        AppConfig.wsUrlFor('https://example.com/commencys'),
        'wss://example.com/commencys/ws/alerts',
      );
      expect(
        AppConfig.wsUrlFor('https://example.com/commencys/'),
        'wss://example.com/commencys/ws/alerts',
      );
    });

    test('setBaseUrl trims and strips trailing slashes', () {
      AppConfig.setBaseUrl('  http://192.168.1.10:8000/  ');
      expect(AppConfig.baseUrl, 'http://192.168.1.10:8000');
      AppConfig.setBaseUrl(AppConfig.defaultBaseUrl);
    });
  });

  test('Incident JSON round-trip', () {
    final now = DateTime.utc(2026, 9, 17, 12, 0, 0);
    final incident = Incident(
      id: '1',
      title: 'Fire',
      description: 'Kitchen fire',
      category: 'fire',
      latitude: -6.2,
      longitude: 106.8,
      severity: IncidentSeverity.high,
      status: IncidentStatus.reported,
      createdAt: now,
      reporterName: 'Tester',
    );
    final restored = Incident.fromJson(incident.toJson());
    expect(restored.title, 'Fire');
    expect(restored.severity, IncidentSeverity.high);
    expect(restored.status, IncidentStatus.reported);
  });

  test('Canonical ticket parses urgency + AI metadata', () {
    final restored = Incident.fromJson({
      'id': 'abc123',
      'title': 'SOS',
      'description': 'One-tap SOS',
      'category': 'sos',
      'latitude': -6.36,
      'longitude': 106.82,
      'accuracy_m': 12.5,
      'urgency': 'P1',
      'urgency_source': 'sos_default_pending_triage',
      'status': 'acknowledged',
      'ai_category': 'fire',
      'ai_confidence': 0.81,
      'needs_review': false,
      'cluster_id': null,
      'created_at': '2026-10-01T00:00:00Z',
      'reporter_name': 'App User',
    });
    expect(restored.urgency, IncidentUrgency.p1);
    expect(restored.status, IncidentStatus.acknowledged);
    expect(restored.accuracyM, 12.5);
    expect(restored.aiConfidence, 0.81);
    expect(restored.needsReview, isFalse);
  });

  test('Lifecycle includes broadcast between ack and dispatch', () {
    expect(IncidentStatus.values.map((e) => e.name), containsAll([
      'reported',
      'acknowledged',
      'broadcast',
      'dispatched',
      'resolved',
    ]));
    expect(IncidentStatus.broadcast.index,
        greaterThan(IncidentStatus.acknowledged.index));
    expect(IncidentStatus.broadcast.index,
        lessThan(IncidentStatus.dispatched.index));
  });
}
