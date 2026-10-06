import 'package:flutter/material.dart';

import '../models/volunteer.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/volunteer_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// First-launch "What is your role?" onboarding — also reused as the
/// profile/settings editor ([RolePickerScreen.editing]).
///
/// Multi-select roles (server-canonical ids), free-text skills
/// (comma-separated), persisted locally via [VolunteerStore] and
/// registered with the backend via `POST /api/volunteers`.
class RolePickerScreen extends StatefulWidget {
  /// When true the screen acts as an editor: pre-fills from the stored
  /// profile and shows a back button instead of blocking onboarding copy.
  final bool editing;

  /// Called after a successful save instead of popping — used by the
  /// first-launch gate (the picker *is* the home route there, so there
  /// is nothing to pop back to).
  final VoidCallback? onSaved;

  const RolePickerScreen({super.key, this.editing = false, this.onSaved});

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

final _roleMeta = <String, (String, IconData, Color, Color)>{
  'medical': (
    'Medical',
    Icons.medical_services_rounded,
    AppColors.accent,
    AppColors.accentSoft,
  ),
  'fire': (
    'Fire',
    Icons.local_fire_department_rounded,
    Color(0xFFF97316),
    Color(0xFFFFEDD5),
  ),
  'rescue': (
    'Rescue',
    Icons.support_outlined,
    AppColors.info,
    AppColors.infoSoft,
  ),
  'security': (
    'Security',
    Icons.shield_outlined,
    Color(0xFF7C3AED),
    Color(0xFFF0E9FD),
  ),
  'driver': (
    'Driver',
    Icons.drive_eta_rounded,
    AppColors.success,
    AppColors.successSoft,
  ),
  'coordinator': (
    'Coordinator',
    Icons.hub_outlined,
    Color(0xFFB45309),
    AppColors.warningSoft,
  ),
};

class _RolePickerScreenState extends State<RolePickerScreen> {
  final _nameCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _api = ApiClient();
  final _location = LocationService();

  Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final stored = await VolunteerStore.load();
    if (!mounted) return;
    setState(() {
      if (stored != null) {
        _nameCtrl.text = stored.name;
        _selected = stored.roles.toSet();
        _skillsCtrl.text = stored.skills.join(', ');
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skillsCtrl.dispose();
    _api.dispose();
    super.dispose();
  }

  List<String> _skills() {
    return _skillsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (_selected.isEmpty) {
      setState(() => _error = 'Pick at least one role.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final roles = Volunteer.allRoles
        .where((r) => _selected.contains(r))
        .toList();
    final skills = _skills();
    try {
      // Persist locally first — the profile works offline.
      await VolunteerStore.save(
        name: name.isEmpty ? 'Volunteer' : name,
        roles: roles,
        skills: skills,
      );
      if (!mounted) return;
      final done = widget.onSaved;
      if (done != null) {
        done();
      } else {
        Navigator.of(context).pop(true);
      }
      // Register with device location (best-effort, never blocks).
      _registerInBackground(
        name: name.isEmpty ? 'Volunteer' : name,
        roles: roles,
        skills: skills,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not save: $e';
          _saving = false;
        });
      }
    }
  }

  Future<void> _registerInBackground({
    required String name,
    required List<String> roles,
    required List<String> skills,
  }) async {
    try {
      final pos = await _location.currentPosition();
      final saved = await _api.registerVolunteer(
        name: name,
        roles: roles,
        skills: skills,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );
      if (saved.id != null) await VolunteerStore.markSynced(saved.id!);
    } catch (_) {
      // Offline: local profile stands; a later save re-registers.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing ? 'Your roles' : 'What is your role?'),
        automaticallyImplyLeading: widget.editing,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiquidGlass(
                    radius: 24,
                    blur: 26,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                color: AppColors.accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.editing
                                    ? 'Update the roles you can cover — special invites follow these.'
                                    : 'Tell us what you can do — urgent incidents that need you will arrive as special invites.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            hintText: 'e.g. Andi',
                            prefixIcon:
                                Icon(Icons.person_outline_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader(title: 'Roles you can cover'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      for (final role in Volunteer.allRoles)
                        _RoleTile(
                          roleId: role,
                          selected: _selected.contains(role),
                          onTap: () => setState(() {
                            if (_selected.contains(role)) {
                              _selected.remove(role);
                            } else {
                              _selected.add(role);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader(title: 'Skills (optional)'),
                  LiquidGlass(
                    radius: 22,
                    blur: 26,
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _skillsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Skills, comma-separated',
                        hintText:
                            'e.g. CPR certified, chainsaw, speaks Javanese',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.accentDeep,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                            ),
                      label: Text(
                        widget.editing
                            ? 'Save roles'
                            : 'Start responding',
                      ),
                    ),
                  ),
                  if (!widget.editing) ...[
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'You can change this anytime from your profile.',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String roleId;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.roleId,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _roleMeta[roleId]!;
    final label = meta.$1;
    final icon = meta.$2;
    final color = meta.$3;
    final tint = meta.$4;
    return LiquidGlass(
      radius: 20,
      blur: 24,
      tint: selected ? 0.85 : 1.0,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? tint : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.6,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 18,
              color: selected ? color : AppColors.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}
