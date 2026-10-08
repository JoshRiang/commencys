// Spesifikasi permintaan SOS untuk klien Flutter; belum dijalankan pada scaffold.
// Aktifkan setelah ApiClient membuat request dan menangani tanda terima server.
import 'dart:convert';

import 'package:commencys/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sendSos forwards the retry key and submitted report fields', () async {
    late http.Request capturedRequest;
    final api = ApiClient(
      baseUrl: 'http://commencys.test',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'id': 'ticket-1',
            'title': 'SOS',
            'description': 'Need medical help',
            'category': 'sos',
            'latitude': -6.2,
            'longitude': 106.8,
            'accuracy_m': 8.0,
            'location_source': 'gps',
            'severity': 'critical',
            'urgency': 'P1',
            'urgency_source': 'sos_default_pending_triage',
            'status': 'acknowledged',
            'created_at': '2026-10-07T12:00:00Z',
            'reporter_name': 'Anonymous',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final ticket = await api.sendSos(
      idempotencyKey: 'retry-key-1',
      latitude: -6.2,
      longitude: 106.8,
      accuracyM: 8,
      locationSource: 'gps',
      description: 'Need medical help',
      reporterName: 'Anonymous',
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/sos');
    expect(capturedRequest.headers['idempotency-key'], 'retry-key-1');
    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['description'], 'Need medical help');
    expect(body['latitude'], -6.2);
    expect(body['location_source'], 'gps');
    expect(ticket['id'], 'ticket-1');
    api.dispose();
  }, skip: 'HTTP behavior is deferred to the implementation phase.');
}
