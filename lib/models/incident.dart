/// Canonical ticket shape — mirrors backend/app/models.py + docs/api-contract.md.
///
/// Lifecycle: reported → acknowledged → broadcast → dispatched → resolved.
/// Raw report fields are immutable; AI writes metadata only (see docs/).
enum IncidentStatus { reported, acknowledged, broadcast, dispatched, resolved }

enum IncidentSeverity { low, medium, high, critical }

/// Urgency P1-Kritis … P4-Rendah (spec station 4). SOS enters as P1 until
/// triage — fail-safe against false negatives (see evaluation-monitoring.md).
enum IncidentUrgency { p1, p2, p3, p4 }

class Incident {
  final String id;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final double? accuracyM;
  final IncidentSeverity severity;
  final IncidentUrgency urgency;
  final String urgencySource;
  final IncidentStatus status;
  final String? aiCategory;
  final double? aiConfidence;
  final bool needsReview;
  final String? clusterId;
  final String? aiSuggestedUrgency;
  final double? aiUrgencyConf;
  final DateTime createdAt;
  final String reporterName;

  /// Targeted-invite metadata (dispatch-auto / WS frames). Empty when the
  /// backend did not attach role targeting — every incident then shows
  /// as a normal broadcast.
  final List<String> requiredRoles;
  final String? inviteReason;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.accuracyM,
    required this.severity,
    this.urgency = IncidentUrgency.p3,
    this.urgencySource = 'reporter_default',
    required this.status,
    this.aiCategory,
    this.aiConfidence,
    this.needsReview = false,
    this.clusterId,
    this.aiSuggestedUrgency,
    this.aiUrgencyConf,
    required this.createdAt,
    required this.reporterName,
    this.requiredRoles = const [],
    this.inviteReason,
  });

  static IncidentUrgency _urgencyFrom(String? v) {
    switch (v?.toUpperCase()) {
      case 'P1':
        return IncidentUrgency.p1;
      case 'P2':
        return IncidentUrgency.p2;
      case 'P4':
        return IncidentUrgency.p4;
      default:
        return IncidentUrgency.p3;
    }
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      severity: IncidentSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => IncidentSeverity.medium,
      ),
      urgency: _urgencyFrom(json['urgency']?.toString()),
      urgencySource:
          json['urgency_source']?.toString() ?? 'reporter_default',
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IncidentStatus.reported,
      ),
      aiCategory: json['ai_category']?.toString(),
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      needsReview: json['needs_review'] == true,
      clusterId: json['cluster_id']?.toString(),
      aiSuggestedUrgency: json['ai_suggested_urgency']?.toString(),
      aiUrgencyConf: (json['ai_urgency_conf'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      reporterName: json['reporter_name']?.toString() ?? 'Anonymous',
      requiredRoles: _roleList(json['required_roles']),
      inviteReason:
          json['reason']?.toString() ?? json['invite_reason']?.toString(),
    );
  }

  /// `required_roles` arrives as a JSON list; be lenient to CSV strings
  /// and null so older backends keep parsing.
  static List<String> _roleList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) {
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_m': accuracyM,
      'severity': severity.name,
      'urgency': urgency.name.toUpperCase(),
      'urgency_source': urgencySource,
      'status': status.name,
      'ai_category': aiCategory,
      'ai_confidence': aiConfidence,
      'needs_review': needsReview,
      'cluster_id': clusterId,
      'ai_suggested_urgency': aiSuggestedUrgency,
      'ai_urgency_conf': aiUrgencyConf,
      'created_at': createdAt.toIso8601String(),
      'reporter_name': reporterName,
      'required_roles': requiredRoles,
      if (inviteReason != null) 'reason': inviteReason,
    };
  }

  /// Roles of [myRoles] that this incident calls for (case-insensitive).
  List<String> matchedRoles(List<String> myRoles) {
    final mine = myRoles.map((r) => r.toLowerCase()).toSet();
    return requiredRoles
        .where((r) => mine.contains(r.toLowerCase()))
        .toList();
  }

  /// True when this incident specially invites a volunteer with [myRoles].
  bool isSpecialInviteFor(List<String> myRoles) =>
      matchedRoles(myRoles).isNotEmpty;

  Incident copyWith({IncidentStatus? status, IncidentSeverity? severity}) {
    return Incident(
      id: id,
      title: title,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      accuracyM: accuracyM,
      severity: severity ?? this.severity,
      urgency: urgency,
      urgencySource: urgencySource,
      status: status ?? this.status,
      aiCategory: aiCategory,
      aiConfidence: aiConfidence,
      needsReview: needsReview,
      clusterId: clusterId,
      aiSuggestedUrgency: aiSuggestedUrgency,
      aiUrgencyConf: aiUrgencyConf,
      createdAt: createdAt,
      reporterName: reporterName,
      requiredRoles: requiredRoles,
      inviteReason: inviteReason,
    );
  }
}
