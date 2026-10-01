import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/incident.dart';

/// HTTP client for the Commencys FastAPI backend (see docs/api-contract.md).
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({this.baseUrl = 'http://10.0.2.2:8000', http.Client? client})
      : _client = client ?? http.Client();

  Future<List<Incident>> fetchIncidents() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/incidents'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load incidents (${res.statusCode})');
    }
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Incident> createIncident({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    double? accuracyM,
    required String severity,
    required String reporterName,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/incidents'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_m': accuracyM,
        'severity': severity,
        'reporter_name': reporterName,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create incident (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// One-tap SOS. Server persists + acknowledges (< 5 s) with P1 fail-safe
  /// urgency until triage; returns the stored ticket (criterion 2).
  Future<Incident> sendSos({
    required double latitude,
    required double longitude,
    double? accuracyM,
    String? description,
    required String reporterName,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/sos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_m': accuracyM,
        'description': description,
        'reporter_name': reporterName,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to send SOS (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Volunteer accepts a ticket: acknowledged/broadcast → dispatched.
  Future<Incident> dispatch({
    required String ticketId,
    required String volunteer,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/incidents/$ticketId/dispatch'
          '?volunteer=${Uri.encodeComponent(volunteer)}'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to dispatch (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
