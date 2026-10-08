import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/urgency_labels.dart';

/// Report as a glass stepped form: 1 What → 2 Category → 3 Urgency →
/// 4 Details. API unchanged: [ApiClient.createIncident].
class ReportScreen extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const ReportScreen({super.key, this.onSubmitted});

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

  /// Local keyword preview — mirrors the backend heuristic client-side so
  /// the reporter sees what AI will likely say. Labelled preview, not final:
  /// the server classifies after submit (spec station 4).
  String _aiPreview() {
    final t =
        '${_titleCtrl.text} ${_descCtrl.text}'.toLowerCase();
    if (t.trim().isEmpty) return '';
    String cat = _category;
    var conf = 'LOW';
    const hints = {
      'fire': ['api', 'kebakaran', 'fire', 'asap', 'terbakar'],
      'medical': ['pingsan', 'jantung', 'sesak', 'luka', 'ambulans'],
      'accident': ['tabrak', 'kecelakaan', 'jatuh', 'crash'],
      'security': ['maling', 'curi', 'begal', 'serang', 'rampok'],
      'facility': ['listrik', 'bocor', 'genset', 'lift'],
    };
    var best = 0;
    hints.forEach((k, words) {
      final hits = words.where((w) => t.contains(w)).length;
      if (hits > best) {
        best = hits;
        cat = k;
      }
    });
    if (best >= 2) {
      conf = 'HIGH';
    } else if (best == 1) {
      conf = 'MEDIUM';
    }
    String urg = 'P3';
    const p1 = ['pingsan', 'tidak sadar', 'jantung', 'sesak', 'terjebak',
      'berdarah', 'kebakaran besar', 'ledakan'];
    const p2 = ['luka parah', 'kebakaran', 'asap tebal', 'bocor gas',
      'begal', 'keracunan'];
    if (p1.any((k) => t.contains(k))) {
      urg = 'P1';
    } else if (p2.any((k) => t.contains(k))) {
      urg = 'P2';
    }
    return 'Looks like: $cat · ${UrgencyLabels.forCode(urg)} ($conf) — AI confirms after submit';
  }
  static const _categories = [
    ('medical', Icons.medical_services_rounded),
    ('accident', Icons.car_crash_rounded),
    ('fire', Icons.local_fire_department_rounded),
    ('security', Icons.shield_outlined),
    ('facility', Icons.business_rounded),
    ('other', Icons.more_horiz_rounded),
  ];
  static const _severities = ['low', 'medium', 'high', 'critical'];

  static const _steps = ['What', 'Category', 'Urgency', 'Details'];

  @override
  void dispose() {
    _api.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  int get _currentStep {
    if (_titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty) {
      return 0;
    }
    // Category and urgency always have a selection; reaching details
    // means steps 1–2 are effectively complete.
    return 3;
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
        reporterName:
            _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent — thank you.')),
      );
      final cb = widget.onSubmitted;
      if (cb != null) {
        cb();
      } else {
        Navigator.pop(context);
      }
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
    final step = _currentStep;
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            LiquidGlass(
              radius: 22,
              blur: 24,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    _StepDot(
                        done: i < step,
                        active: i == step,
                        label: _steps[i]),
                    if (i < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(2),
                            color: i < step
                                ? AppColors.success
                                : Colors.black.withValues(
                                    alpha: 0.08),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: '1 · What happened?'),
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
                  Builder(builder: (context) {
                    final preview = _aiPreview();
                    if (preview.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_outlined,
                            size: 14,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'AI preview · $preview',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: '2 · Category'),
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
            const SectionHeader(title: '3 · How urgent?'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How fast does this need help? Laya confirms after you send.',
                    style: TextStyle(
                        color: AppColors.secondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _severities)
                        ChoiceChip(
                          label: Text(
                              UrgencyLabels.forSeverity(s)),
                          selected: _severity == s,
                          onSelected: (_) =>
                              setState(() => _severity = s),
                          selectedColor:
                              AppColors.severitySoftFor(s),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: _severity == s
                                ? AppColors.severityFor(s)
                                : AppColors.secondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(999),
                            side: BorderSide(
                              color: _severity == s
                                  ? AppColors.severityFor(s)
                                  : Colors.black
                                      .withValues(alpha: 0.08),
                            ),
                          ),
                          showCheckmark: false,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: '4 · Your details'),
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

class _StepDot extends StatelessWidget {
  final bool done;
  final bool active;
  final String label;

  const _StepDot({
    required this.done,
    required this.active,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = done || active
        ? AppColors.accent
        : AppColors.tertiary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: active ? 26 : 22,
          height: active ? 26 : 22,
          decoration: BoxDecoration(
            color: done || active
                ? AppColors.accent
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: done || active
                  ? AppColors.accent
                  : Colors.black.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded,
                  size: 14, color: Colors.white)
              : active
                  ? Container(
                      margin: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                active ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
