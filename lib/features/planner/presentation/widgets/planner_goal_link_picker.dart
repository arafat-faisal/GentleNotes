/// Bottom sheet for linking a goal to a planner item.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../features/goals/presentation/controllers/goals_controller.dart';
import '../../../../../features/goals/domain/entities/goal_entity.dart';
import '../../../../../features/goals/domain/entities/goal_enums.dart';

class PlannerGoalLinkPicker extends ConsumerWidget {
  const PlannerGoalLinkPicker({
    super.key,
    required this.selectedGoalId,
    required this.onChanged,
  });

  final String? selectedGoalId;
  final ValueChanged<String?> onChanged;

  /// Opens the goal link picker bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String? currentGoalId,
    required ValueChanged<String?> onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProviderScope(
        child: PlannerGoalLinkPicker(
          selectedGoalId: currentGoalId,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allGoals = ref.watch(goalsProvider);
    final activeGoals = allGoals.where((g) => g.status == GoalStatus.active).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
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
                  Text('Link a Goal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Select an active goal to attach to this plan.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  // Clear link option
                  if (selectedGoalId != null)
                    TextButton.icon(
                      onPressed: () {
                        onChanged(null);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.link_off_rounded, size: 16),
                      label: const Text('Remove link'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: activeGoals.isEmpty
                  ? Center(
                      child: Text(
                        'No active goals available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: activeGoals.length,
                      itemBuilder: (context, index) {
                        final goal = activeGoals[index];
                        final isSelected = goal.id == selectedGoalId;
                        return _GoalListTile(
                          goal: goal,
                          isSelected: isSelected,
                          onTap: () {
                            onChanged(goal.id);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalListTile extends StatelessWidget {
  const _GoalListTile({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  final GoalEntity goal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4))
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(Icons.flag_outlined, color: theme.colorScheme.primary, size: 20),
        title: Text(
          goal.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
        ),
        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
        onTap: onTap,
      ),
    );
  }
}
