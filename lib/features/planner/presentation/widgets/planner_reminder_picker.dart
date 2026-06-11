/// Bottom sheet for selecting a reminder (minutes before event).
library;

import 'package:flutter/material.dart';

class PlannerReminderPicker extends StatelessWidget {
  const PlannerReminderPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;

  static const _options = [
    (label: 'No Reminder', value: null),
    (label: '5 min before', value: 5),
    (label: '10 min before', value: 10),
    (label: '15 min before', value: 15),
    (label: '30 min before', value: 30),
    (label: '1 hour before', value: 60),
    (label: '2 hours before', value: 120),
    (label: '1 day before', value: 1440),
  ];

  /// Opens the reminder picker bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required int? current,
    required ValueChanged<int?> onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlannerReminderPicker(selected: current, onChanged: onChanged),
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
            Text('Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._options.map((opt) {
              final isSelected = opt.value == selected;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: Icon(
                  opt.value == null ? Icons.notifications_off_outlined : Icons.alarm_outlined,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                title: Text(
                  opt.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: theme.colorScheme.primary) : null,
                onTap: () {
                  onChanged(opt.value);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
