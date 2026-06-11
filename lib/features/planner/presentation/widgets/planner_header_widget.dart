/// Header widget for the Today view.
///
/// Shows a greeting, today's date, and a stat strip (planned/completed).
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerHeaderWidget extends StatelessWidget {
  const PlannerHeaderWidget({super.key, required this.todayItems});

  final List<PlannerItemEntity> todayItems;

  static final _dateFmt = DateFormat('EEEE, d MMMM');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final total = todayItems.length;
    final completed = todayItems.where((i) => i.isCompleted).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dateFmt.format(DateTime.now()),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          // ── Stat strip ──
          Row(
            children: [
              _StatChip(
                icon: Icons.calendar_today_outlined,
                label: '$total planned',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                label: '$completed completed',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
