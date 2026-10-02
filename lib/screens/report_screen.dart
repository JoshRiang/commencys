import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiClient();
  final _location = LocationService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _category = 'medical';
  String _severity = 'medium';
  bool _sending = false;

  static const _categories = [
    ('medical', Icons.medical_services_rounded),
    ('accident', Icons.car_crash_rounded),
    ('fire', Icons.local_fire_department_rounded),
    ('security', Icons.shield_outlined),
    ('facility', Icons.business_rounded),
    ('other', Icons.more_horiz_rounded),
  ];
  static const _severities = ['low', 'medium', 'high', 'critical'];

  @override
  void dispose() {
    _api.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final pos = await _location.currentPosition();
      await _api.createIncident(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        latitude: pos?.latitude ?? -6.2,
        longitude: pos?.longitude ?? 106.8,
        accuracyM: pos?.accuracy,
        severity: _severity,
        reporterName:
            _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent — thank you.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const SectionHeader(title: 'What happened?'),
            GlassCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Fire on the 2nd floor',
                      prefixIcon: Icon(Icons.title_rounded, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What do you see? Where exactly?',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Category'),
            GlassCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, icon) in _categories)
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15),
                          const SizedBox(width: 6),
                          Text(value),
                        ],
                      ),
                      selected: _category == value,
                      onSelected: (_) =>
                          setState(() => _category = value),
                      selectedColor: AppColors.accentSoft,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _category == value
                            ? AppColors.accentDeep
                            : AppColors.secondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _category == value
                              ? AppColors.accent
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'How urgent?'),
            GlassCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _severities)
                    ChoiceChip(
                      label: Text(s.toUpperCase()),
                      selected: _severity == s,
                      onSelected: (_) =>
                          setState(() => _severity = s),
                      selectedColor: AppColors.severitySoftFor(s),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: _severity == s
                            ? AppColors.severityFor(s)
                            : AppColors.secondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: _severity == s
                              ? AppColors.severityFor(s)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Your details'),
            GlassCard(
              child: TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your name (optional)',
                  hintText: 'Anonymous is fine',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 19),
              label: Text(_sending ? 'Sending...' : 'Submit report'),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Your GPS is attached automatically.',
                style:
                    TextStyle(color: AppColors.secondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
