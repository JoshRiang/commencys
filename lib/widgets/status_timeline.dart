import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../theme/app_theme.dart';

/// Transparent ticket-lifecycle stepper (spec criterion 3):
/// acknowledged ≠ dispatched. Each stage renders distinctly so a reporter
/// never mistakes "stored by system" for "help is coming".
class StatusTimeline extends StatelessWidget {
  final IncidentStatus status;

  const StatusTimeline({super.key, required this.status});

  static const _steps = [
    (IncidentStatus.acknowledged, 'Received', 'Report saved by the system'),
    (IncidentStatus.broadcast, 'Shared', 'Nearby volunteers notified'),
    (IncidentStatus.dispatched, 'Help on the way', 'A volunteer took the job'),
    (IncidentStatus.resolved, 'Resolved', 'Done'),
  ];

  static const _icons = [
    Icons.inbox_rounded,
    Icons.campaign_outlined,
    Icons.directions_run_rounded,
    Icons.check_circle_rounded,
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
              _Dot(done: i <= current, active: i == current, icon: _icons[i]),
              if (i < _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < current
                          ? AppColors.success
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: current >= 2
                ? AppColors.successSoft
                : AppColors.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            current < 0
                ? 'Sending…'
                : '${_steps[current].$2} — ${_steps[current].$3}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: current >= 2
                  ? AppColors.success
                  : AppColors.accentDeep,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool done;
  final bool active;
  final IconData icon;

  const _Dot({required this.done, required this.active, required this.icon});

  @override
  Widget build(BuildContext context) {
    final size = active ? 34.0 : 28.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: done ? AppColors.success : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: done
              ? AppColors.success
              : Colors.black.withValues(alpha: 0.12),
          width: active ? 2.5 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        done ? icon : Icons.circle_outlined,
        size: 15,
        color: done ? Colors.white : AppColors.tertiary,
      ),
    );
  }
}
