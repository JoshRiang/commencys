import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/incident.dart';
import '../models/volunteer.dart';
import 'app_config.dart';

/// HTTP client for the Commencys FastAPI backend (see docs/api-contract.md).
class ApiClient {
  /// Hard ceiling per request so a phone on a dead network fails fast
  /// (10 s) instead of hanging the UI indefinitely.
  static const requestTimeout = Duration(seconds: 10);

  final String baseUrl;
  final http.Client _client;

  /// Headers for write ops. The public demo proxy requires `X-Demo-Key`
  /// on POST/PUT/PATCH/DELETE; empty locally (no-op) when no key is baked.
  static Map<String, String> _writeHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{...?extra};
    if (AppConfig.demoKey.isNotEmpty) {
      headers['X-Demo-Key'] = AppConfig.demoKey;
    }
    return headers;
  }

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? http.Client();

  Future<List<Incident>> fetchIncidents() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/incidents'))
        .timeout(requestTimeout);
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
    required String reporterName,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/incidents'),
          headers: _writeHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'title': title,
            'description': description,
            'category': category,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy_m': accuracyM,
            'reporter_name': reporterName,
          }),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create incident (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Text SOS (typed note + GPS → POST /api/sos). Used by the type-SOS
  /// widget; the server persists + acknowledges (< 5 s) with P1 fail-safe
  /// urgency until triage; returns the stored ticket (criterion 2).
  Future<Incident> sendSos({
    required double latitude,
    required double longitude,
    double? accuracyM,
    String? description,
    required String reporterName,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/sos'),
          headers: _writeHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
            'accuracy_m': accuracyM,
            'description': description,
            'reporter_name': reporterName,
          }),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to send SOS (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Voice SOS (multipart `audio` + GPS fields → POST /api/sos-voice).
  /// Same P1 fail-safe ack as [sendSos]; the demo proxy `X-Demo-Key`
  /// goes on as a plain header alongside the multipart boundary.
  /// [onProgress01] fires 0→1 across record-upload wait + byte send so
  /// the widget can show one honest progress bar for the whole step.
  Future<Incident> sendSosVoice({
    required File audioFile,
    required double latitude,
    required double longitude,
    double? accuracyM,
    String? description,
    double? durationS,
    required String reporterName,
    void Function(double progress01)? onProgress01,
  }) async {
    onProgress01?.call(0.05);
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/sos-voice'),
    );
    // Multipart write: demo key as header (never in the body).
    for (final entry in _writeHeaders().entries) {
      req.headers[entry.key] = entry.value;
    }
    req.fields['latitude'] = '$latitude';
    req.fields['longitude'] = '$longitude';
    if (accuracyM != null) req.fields['accuracy_m'] = '$accuracyM';
    if (description != null && description.isNotEmpty) {
      req.fields['description'] = description;
    }
    if (durationS != null) req.fields['duration_s'] = '$durationS';
    req.fields['reporter_name'] = reporterName;
    req.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
    onProgress01?.call(0.25);
    final streamed =
        await _client.send(req).timeout(requestTimeout);
    onProgress01?.call(0.8);
    final res = await http.Response.fromStream(streamed);
    onProgress01?.call(1.0);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to send voice SOS (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Volunteer accepts a ticket: acknowledged/broadcast → dispatched.
  Future<Incident> dispatch({
    required String ticketId,
    required String volunteer,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/incidents/$ticketId/dispatch'
              '?volunteer=${Uri.encodeComponent(volunteer)}'),
          headers: _writeHeaders(),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to dispatch (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Coordinator triage inbox: tickets AI flagged for human review.
  Future<List<Incident>> fetchReviewQueue() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/review-queue'))
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load review queue (${res.statusCode})');
    }
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Coordinator correction — metadata only, raw report stays immutable.
  Future<Incident> correctTicket({
    required String ticketId,
    String? aiCategory,
    String? urgency,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/incidents/$ticketId/correct'),
          headers: _writeHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'ai_category': aiCategory,
            'urgency': urgency,
          }),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to correct ticket (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Reversible clustering: clear this ticket's cluster link.
  Future<Incident> splitCluster({required String ticketId}) async {
    final res = await _client
        .post(Uri.parse('$baseUrl/api/incidents/$ticketId/split'),
            headers: _writeHeaders())
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to split cluster (${res.statusCode})');
    }
    return Incident.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Immutable audit trail for one ticket (spec station 9).
  Future<List<Map<String, dynamic>>> fetchAudit(String ticketId) async {
    final res = await _client
        .get(Uri.parse(
            '$baseUrl/api/audit?incident_id=${Uri.encodeComponent(ticketId)}'))
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load audit (${res.statusCode})');
    }
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Register (or update) this device as a volunteer.
  ///
  /// Contract: POST /api/volunteers
  /// `{name, roles:[medical|fire|rescue|security|driver|coordinator],
  /// skills:[], latitude, longitude}` → 201 `{id, ...}`.
  /// Backend [VolunteerIn] requires coordinates, so callers fall back to
  /// the Jakarta area pin when the device has no fix yet.
  static const defaultLatitude = -6.2;
  static const defaultLongitude = 106.8;

  Future<Volunteer> registerVolunteer({
    required String name,
    required List<String> roles,
    List<String> skills = const [],
    double? latitude,
    double? longitude,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/volunteers'),
          headers: _writeHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'name': name,
            'roles': roles,
            'skills': skills,
            'latitude': latitude ?? defaultLatitude,
            'longitude': longitude ?? defaultLongitude,
          }),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Failed to register volunteer (${res.statusCode})',
      );
    }
    return Volunteer.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  void dispose() => _client.close();
}
