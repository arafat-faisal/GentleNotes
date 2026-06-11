/// Priority selector widget — Low / Medium / High segmented chips.
library;

import 'package:flutter/material.dart';
import '../../domain/entities/planner_enums.dart';

class PlannerPrioritySelector extends StatelessWidget {
  const PlannerPrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PlannerPriority selected;
  final ValueChanged<PlannerPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PlannerPriority.values.map((priority) {
        final isSelected = priority == selected;
        final color = _priorityColor(priority);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(priority),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                priority.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : color.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _priorityColor(PlannerPriority p) {
    switch (p) {
      case PlannerPriority.low:    return const Color(0xFF10B981);
      case PlannerPriority.medium: return const Color(0xFFF59E0B);
      case PlannerPriority.high:   return const Color(0xFFF43F5E);
    }
  }
}
