import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'urgency_labels.dart';

/// Shared AI triage badges — same Liquid Glass language everywhere.
///
/// Shows: `AI {category} {pct}%` pill, amber `needs review` pill when
/// flagged, and a tappable `cluster: N nearby` chip when clustered.
/// AI output is advisory only — never blocks SOS, never auto-downgrades.
class AiTriageBadges extends StatelessWidget {
  final Incident incident;
  final int? clusterSize;
  final VoidCallback? onClusterTap;

  const AiTriageBadges({
    super.key,
    required this.incident,
    this.clusterSize,
    this.onClusterTap,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    final cat = incident.aiCategory;
    final conf = incident.aiConfidence;
    if (cat != null && conf != null) {
      chips.add(Pill(
        label: 'AI $cat ${(conf * 100).round()}%',
        bg: AppColors.infoSoft,
        fg: AppColors.info,
        icon: Icons.auto_awesome_outlined,
      ));
    }
    final urg = incident.aiSuggestedUrgency;
    if (urg != null && incident.urgencySource == 'ai_triage_pending_review') {
      chips.add(Pill(
        label: 'AI: ${UrgencyLabels.forCode(urg)}?',
        bg: AppColors.accentSoft,
        fg: AppColors.accentDeep,
        icon: Icons.arrow_upward_rounded,
      ));
    }
    if (incident.needsReview) {
      chips.add(const Pill(
        label: 'needs review',
        bg: AppColors.warningSoft,
        fg: Color(0xFFB45309),
        icon: Icons.rate_review_outlined,
      ));
    }
    final cid = incident.clusterId;
    if (cid != null) {
      final n = clusterSize;
      chips.add(GestureDetector(
        onTap: onClusterTap,
        child: Pill(
          label: n != null ? 'cluster: $n nearby' : 'cluster',
          bg: AppColors.successSoft,
          // Darkened vs AppColors.success so 12 pt bold text keeps
          // 4.5:1 on the soft green (was 2.9:1).
          fg: const Color(0xFF15803D),
          icon: Icons.hub_outlined,
        ),
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}

/// Bottom-sheet with coordinator actions: correct category/urgency and
/// split a false-merged cluster. Calls the new endpoints via callbacks so
/// screens keep their own ApiClient lifecycle.
class CoordinatorActionsSheet extends StatelessWidget {
  final Incident incident;
  final Future<void> Function({String? category, String? urgency}) onCorrect;
  final Future<void> Function() onSplit;

  const CoordinatorActionsSheet({
    super.key,
    required this.incident,
    required this.onCorrect,
    required this.onSplit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: LiquidGlass(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incident.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            AiTriageBadges(incident: incident),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await onCorrect(category: incident.aiCategory);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm AI label'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await onSplit();
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.call_split_rounded, size: 18),
                    label: const Text('Split cluster'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
