import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_theme.dart';

/// Plain-language urgency labels for regular people (ID + EN).
///
/// P1 = need help NOW · P2 = urgent, respond fast · P3 = standard queue ·
/// P4 = low, info / follow-up. The raw `P1…P4` code is always kept as a
/// suffix so coordinator/backend talk stays unambiguous.
///
/// Single source of truth — every urgency/severity surface (SOS ticket
/// card, alerts list, map sheet + pins, AI suggestion chips, report
/// picker) renders through [UrgencyLabels].
class UrgencyLabels {
  const UrgencyLabels._();

  /// Canonical label for an [IncidentUrgency]: `P1 · Segera / NOW`.
  static String forUrgency(IncidentUrgency u) {
    switch (u) {
      case IncidentUrgency.p1:
        return 'P1 · Segera / NOW';
      case IncidentUrgency.p2:
        return 'P2 · Cepat / Urgent';
      case IncidentUrgency.p3:
        return 'P3 · Antre / Standard';
      case IncidentUrgency.p4:
        return 'P4 · Ringan / Low';
    }
  }

  /// Parse a backend `P1…P4` string (case-insensitive) to a plain label.
  /// Unknown input falls back to P3 (reporter default).
  static String forCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'P1':
        return forUrgency(IncidentUrgency.p1);
      case 'P2':
        return forUrgency(IncidentUrgency.p2);
      case 'P4':
        return forUrgency(IncidentUrgency.p4);
      case 'P3':
      default:
        return forUrgency(IncidentUrgency.p3);
    }
  }

  /// Plain-language label for the legacy severity scale shown on pins,
  /// map sheets and the alerts list.
  static String forSeverity(String name) {
    switch (name) {
      case 'critical':
        return 'Kritis / Critical';
      case 'high':
        return 'Tinggi / High';
      case 'low':
        return 'Rendah / Low';
      case 'medium':
      default:
        return 'Sedang / Medium';
    }
  }

  /// Pill background for an urgency level (P1 red → P4 green).
  static Color urgencyBg(IncidentUrgency u) {
    switch (u) {
      case IncidentUrgency.p1:
        return AppColors.accentSoft;
      case IncidentUrgency.p2:
        return const Color(0xFFFFEDD5);
      case IncidentUrgency.p3:
        return const Color(0xFFFEF9C3);
      case IncidentUrgency.p4:
        return AppColors.successSoft;
    }
  }

  /// Pill foreground for an urgency level.
  ///
  /// All pairs clear their WCAG bar on their pill background (P1 5.0:1,
  /// P2 4.5:1, P3 4.6:1, P4 4.5:1 — body/bold text needs 4.5:1 up to
  /// 17 pt, 3:1 when bold).
  static Color urgencyFg(IncidentUrgency u) {
    switch (u) {
      case IncidentUrgency.p1:
        return AppColors.accentDeep;
      case IncidentUrgency.p2:
        return const Color(0xFFC2410C);
      case IncidentUrgency.p3:
        return const Color(0xFFA16207);
      case IncidentUrgency.p4:
        return const Color(0xFF15803D);
    }
  }
}
