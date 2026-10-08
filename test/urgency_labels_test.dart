import 'package:commencys/models/incident.dart';
import 'package:commencys/widgets/urgency_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrgencyLabels', () {
    test('plain-language urgency keeps the P-code for coordinators', () {
      expect(UrgencyLabels.forUrgency(IncidentUrgency.p1),
          'P1 · Segera / NOW');
      expect(UrgencyLabels.forUrgency(IncidentUrgency.p2),
          'P2 · Cepat / Urgent');
      expect(UrgencyLabels.forUrgency(IncidentUrgency.p3),
          'P3 · Antre / Standard');
      expect(UrgencyLabels.forUrgency(IncidentUrgency.p4),
          'P4 · Ringan / Low');
    });

    test('forCode parses backend strings, falls back to P3', () {
      expect(UrgencyLabels.forCode('P1'), 'P1 · Segera / NOW');
      expect(UrgencyLabels.forCode('p2'), 'P2 · Cepat / Urgent');
      expect(UrgencyLabels.forCode(null), 'P3 · Antre / Standard');
      expect(UrgencyLabels.forCode('P9'), 'P3 · Antre / Standard');
    });

    test('severity speaks plainly in both languages', () {
      expect(
          UrgencyLabels.forSeverity('critical'), 'Kritis / Critical');
      expect(UrgencyLabels.forSeverity('high'), 'Tinggi / High');
      expect(UrgencyLabels.forSeverity('medium'), 'Sedang / Medium');
      expect(UrgencyLabels.forSeverity('low'), 'Rendah / Low');
    });
  });
}
