import 'package:flutter/material.dart';

import '../models/incident.dart';

/// Transparent ticket-lifecycle stepper (spec criterion 3):
/// acknowledged ≠ dispatched. Each stage renders distinctly so a reporter
/// never mistakes "stored by system" for "help is coming".
class StatusTimeline extends StatelessWidget {
  final IncidentStatus status;

  const StatusTimeline({super.key, required this.status});

  static const _steps = [
    (IncidentStatus.acknowledged, 'Received', 'Laporan diterima sistem'),
    (IncidentStatus.broadcast, 'Broadcast', 'Relawan diberi tahu'),
    (IncidentStatus.dispatched, 'Dispatched', 'Relawan mengambil tugas'),
    (IncidentStatus.resolved, 'Resolved', 'Selesai'),
  ];

  int get _current {
    if (status == IncidentStatus.reported) return -1;
    final i = _steps.indexWhere((s) => s.$1 == status);
    return i;
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              _Dot(done: i <= current, active: i == current),
              if (i < _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i < current ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          current < 0
              ? 'Sending…'
              : '${_steps[current].$2} — ${_steps[current].$3}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: current >= 2 ? Colors.green.shade800 : Colors.red.shade800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool done;
  final bool active;

  const _Dot({required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 22 : 16,
      height: active ? 22 : 16,
      decoration: BoxDecoration(
        color: done ? Colors.green : Colors.grey.shade300,
        shape: BoxShape.circle,
        border: active
            ? Border.all(color: Colors.green.shade900, width: 2)
            : null,
      ),
    );
  }
}
