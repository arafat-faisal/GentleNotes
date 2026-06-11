/// Color-coded chip showing the planner item type.
library;

import 'package:flutter/material.dart';
import '../../domain/entities/planner_enums.dart';

class PlannerTypeChip extends StatelessWidget {
  const PlannerTypeChip({super.key, required this.type, this.small = false});

  final PlannerItemType type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor(type, theme);
    final fontSize = small ? 10.0 : 11.0;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 3);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        '${type.emoji}  ${type.displayName}',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _typeColor(PlannerItemType t, ThemeData theme) {
    switch (t) {
      case PlannerItemType.task:         return const Color(0xFF10B981);
      case PlannerItemType.meeting:      return const Color(0xFF3B82F6);
      case PlannerItemType.studySession: return const Color(0xFF8B5CF6);
      case PlannerItemType.exam:         return const Color(0xFFF43F5E);
      case PlannerItemType.deadline:     return const Color(0xFFF59E0B);
      case PlannerItemType.habit:        return const Color(0xFF6366F1);
    }
  }
}
