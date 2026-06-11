/// Bottom sheet for picking recurrence frequency.
library;

import 'package:flutter/material.dart';
import '../../domain/entities/planner_enums.dart';

class PlannerRecurrencePicker extends StatelessWidget {
  const PlannerRecurrencePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RecurrenceFrequency selected;
  final ValueChanged<RecurrenceFrequency> onChanged;

  /// Opens the recurrence picker bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required RecurrenceFrequency current,
    required ValueChanged<RecurrenceFrequency> onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlannerRecurrencePicker(selected: current, onChanged: onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Repeat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...RecurrenceFrequency.values.map((freq) {
              final isSelected = freq == selected;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: Icon(
                  _freqIcon(freq),
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                title: Text(
                  freq.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: theme.colorScheme.primary) : null,
                onTap: () {
                  onChanged(freq);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _freqIcon(RecurrenceFrequency f) {
    switch (f) {
      case RecurrenceFrequency.none:    return Icons.block_outlined;
      case RecurrenceFrequency.daily:   return Icons.today_outlined;
      case RecurrenceFrequency.weekly:  return Icons.view_week_outlined;
      case RecurrenceFrequency.monthly: return Icons.calendar_month_outlined;
    }
  }
}
