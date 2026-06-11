/// Horizontal color dot row for picking an item's color accent.
library;

import 'package:flutter/material.dart';

class PlannerColorPicker extends StatelessWidget {
  const PlannerColorPicker({
    super.key,
    required this.selectedHex,
    required this.onChanged,
  });

  final String selectedHex;
  final ValueChanged<String> onChanged;

  static const _colors = [
    '#8B5CF6', // Violet
    '#6366F1', // Indigo
    '#3B82F6', // Blue
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#F43F5E', // Rose
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#F97316', // Orange
    '#64748B', // Slate
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final hex = _colors[index];
          final isSelected = hex == selectedHex;
          final color = _hexToColor(hex);
          return GestureDetector(
            onTap: () => onChanged(hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
