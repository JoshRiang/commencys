import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/volunteer.dart';

/// Local persistence for the volunteer's own role profile.
///
/// Single source of truth for "what is your role" across the app:
/// onboarding [RolePickerScreen], alerts invite matching, and the
/// profile/settings edit entry point all read through here.
class VolunteerStore {
  static const keyName = 'volunteer_name';
  static const keyRoles = 'volunteer_roles';
  static const keySkills = 'volunteer_skills';
  static const keyId = 'volunteer_id';
  static const keySyncedAt = 'volunteer_synced_at';

  /// True once the user completed the first-launch role picker.
  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(keyRoles);
  }

  static Future<Volunteer?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(keyRoles)) return null;
    return Volunteer(
      id: prefs.getString(keyId),
      name: prefs.getString(keyName) ?? '',
      roles: List<String>.from(
        jsonDecode(prefs.getString(keyRoles) ?? '[]') as List,
      ),
      skills: List<String>.from(
        jsonDecode(prefs.getString(keySkills) ?? '[]') as List,
      ),
    );
  }

  static Future<List<String>> roles() async {
    final v = await load();
    return v?.roles ?? const [];
  }

  /// Roles of [requiredRoles] covered by the stored profile.
  static Future<List<String>> matchedRoles(
    List<String> requiredRoles,
  ) async {
    final mine = await roles();
    final mineLower = mine.map((r) => r.toLowerCase()).toSet();
    return requiredRoles
        .where((r) => mineLower.contains(r.toLowerCase()))
        .toList();
  }

  static Future<Volunteer> save({
    String? id,
    required String name,
    required List<String> roles,
    required List<String> skills,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyName, name);
    await prefs.setString(keyRoles, jsonEncode(roles));
    await prefs.setString(keySkills, jsonEncode(skills));
    if (id != null) {
      await prefs.setString(keyId, id);
      await prefs.setString(
        keySyncedAt,
        DateTime.now().toIso8601String(),
      );
    }
    return Volunteer(id: id, name: name, roles: roles, skills: skills);
  }

  static Future<void> markSynced(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyId, id);
    await prefs.setString(
      keySyncedAt,
      DateTime.now().toIso8601String(),
    );
  }
}
