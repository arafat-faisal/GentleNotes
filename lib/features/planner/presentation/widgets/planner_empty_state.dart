/// Planner-specific empty state widget.
///
/// Wraps [AppEmptyState] with planner-specific defaults.
library;

import 'package:flutter/material.dart';
import '../../../../../shared/widgets/app_empty_state.dart';

class PlannerEmptyState extends StatelessWidget {
  const PlannerEmptyState({
    super.key,
    this.title = 'No plans yet.',
    this.subtitle = 'Add a study session, task, or deadline.',
    this.onAdd,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.calendar_today_outlined,
      title: title,
      subtitle: subtitle,
      actionLabel: onAdd != null ? 'Add Plan' : null,
      onAction: onAdd,
    );
  }
}
