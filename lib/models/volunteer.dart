/// Volunteer profile — mirrors `POST /api/volunteers` contract.
///
/// Roles are server-canonical lowercase ids:
/// medical | fire | rescue | security | driver | coordinator.
class Volunteer {
  static const allRoles = [
    'medical',
    'fire',
    'rescue',
    'security',
    'driver',
    'coordinator',
  ];

  final String? id;
  final String name;
  final List<String> roles;
  final List<String> skills;
  final double? latitude;
  final double? longitude;

  const Volunteer({
    this.id,
    required this.name,
    required this.roles,
    this.skills = const [],
    this.latitude,
    this.longitude,
  });

  /// Roles of [requiredRoles] that this volunteer can cover.
  List<String> matchedRoles(List<String> requiredRoles) {
    final mine = roles.map((r) => r.toLowerCase()).toSet();
    return requiredRoles
        .where((r) => mine.contains(r.toLowerCase()))
        .toList();
  }

  bool isInvitedBy(List<String> requiredRoles) =>
      matchedRoles(requiredRoles).isNotEmpty;

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      roles: _stringList(json['roles']),
      skills: _stringList(json['skills']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'roles': roles,
      'skills': skills,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  Volunteer copyWith({
    String? id,
    String? name,
    List<String>? roles,
    List<String>? skills,
    double? latitude,
    double? longitude,
  }) {
    return Volunteer(
      id: id ?? this.id,
      name: name ?? this.name,
      roles: roles ?? this.roles,
      skills: skills ?? this.skills,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
