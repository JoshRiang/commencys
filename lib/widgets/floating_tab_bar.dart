import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass.dart';

/// Vertical clearance reserved above the system bottom inset for the
/// floating glass tab bar (shared by [AppShell] padding and map overlays).
const double kFloatingTabBarClearance = 96.0;

/// Floating Apple Liquid Glass bottom navigation.
///
/// Full-width glass pill floating over content; the Map destination sits in
/// the center as a raised red home button — the map is the home screen.
class FloatingGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingGlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.edit_note_rounded, 'Report'),
    (Icons.map_rounded, 'Map'),
    (Icons.notifications_rounded, 'Alerts'),
    (Icons.sos_rounded, 'SOS'),
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      radius: 28,
      blur: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _items.length; i++)
            if (i == 2)
              _CenterMapButton(
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              )
            else
              _TabItem(
                icon: _items[i].$1,
                label: _items[i].$2,
                selected: currentIndex == i,
                alert: i == 4,
                onTap: () => onTap(i),
              ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool alert;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.accent
        : alert
            ? AppColors.accent.withValues(alpha: 0.65)
            : AppColors.secondary;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMapButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CenterMapButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.sosStart, AppColors.sosEnd],
              ),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.map_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Map',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.accent : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
