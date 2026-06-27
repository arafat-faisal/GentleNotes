import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/gentle_scaffold.dart';
import '../../notes/presentation/controllers/notes_controller.dart';
import '../../planner/presentation/controllers/planner_controller.dart';
import '../domain/entities/goal_enums.dart';
import 'controllers/goals_controller.dart';
import 'widgets/goal_failure_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final goal = goals.where((g) => g.id == goalId).firstOrNull;

    if (goal == null) {
      return GentleScaffold(
        title: 'Not Found',
        showBackButton: true,
        body: const Center(child: Text('Goal not found')),
      );
    }

    final theme = Theme.of(context);
    final plannerState = ref.watch(plannerProvider);
    final linkedTasks = plannerState.items.where((item) => item.linkedGoalId == goal.id).toList();

    final notes = ref.watch(notesProvider);
    final linkedNotes = notes.where((note) => goal.relatedNoteIds.contains(note.id)).toList();

    return GentleScaffold(
      title: 'Goal Details',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirmed = await _confirmDelete(context);
            if (confirmed && context.mounted) {
              await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
              if (context.mounted) context.pop();
            }
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/goals/edit_form/${goal.id}'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text(goal.horizon.displayName)),
                      const SizedBox(width: 8),
                      Chip(label: Text(goal.status.name.toUpperCase())),
                      const SizedBox(width: 8),
                      Chip(label: Text('Priority: ${goal.priority.name.toUpperCase()}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (goal.description.isNotEmpty) ...[
                    Text(
                      goal.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (goal.status == GoalStatus.failed) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Failure Reason', style: theme.textTheme.titleMedium?.copyWith(color: Colors.red)),
                          Text(goal.failureReason),
                          const SizedBox(height: 8),
                          Text('Lessons Learned', style: theme.textTheme.titleMedium?.copyWith(color: Colors.red)),
                          Text(goal.lessonsLearned),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry Goal'),
                            onPressed: () async {
                              await ref.read(goalsProvider.notifier).retryGoal(goal);
                              if (context.mounted) context.pop();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Prominent visual progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(goal.progressPercentage * 100).toInt()}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: goal.progressPercentage,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Steps', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (goal.steps.isEmpty)
                    const Text('No steps defined.')
                  else
                    ...goal.steps.map((step) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          step.title,
                          style: TextStyle(
                            decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                            color: step.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        value: step.isCompleted,
                        onChanged: goal.status == GoalStatus.active
                            ? (val) {
                                ref.read(goalsProvider.notifier).toggleStep(goal, step.id);
                              }
                            : null, // disable if not active
                      );
                    }),

                  // Linked Notes Section
                  if (linkedNotes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Linked Notes',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...linkedNotes.map((note) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.note_alt_outlined, color: theme.colorScheme.primary),
                          title: Text(note.title),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/notes/edit/${note.id}'),
                        ),
                      );
                    }),
                  ],

                  // Linked Planner Tasks Section
                  if (linkedTasks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Linked Daily Tasks',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...linkedTasks.map((task) {
                      final dateStr = DateFormat('MMM d, yyyy').format(task.date);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                        ),
                        child: ListTile(
                          leading: Icon(
                            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: task.isCompleted ? Colors.green : theme.colorScheme.primary,
                          ),
                          title: Text(task.title, style: TextStyle(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          )),
                          subtitle: Text(dateStr),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/planner/detail/${task.id}'),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 32),

                  if (goal.status == GoalStatus.active)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          icon: const Icon(Icons.close),
                          label: const Text('Mark Failed'),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (ctx) => GoalFailureSheet(
                                onSubmit: (reason, lessons) async {
                                  await ref.read(goalsProvider.notifier).failGoal(
                                    goal: goal,
                                    failureReason: reason,
                                    lessonsLearned: lessons,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check),
                          label: const Text('Mark Achieved'),
                          onPressed: () async {
                            await ref.read(goalsProvider.notifier).markAchieved(goal);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Google AdMob Banner Ad Placeholder
          SafeArea(
            top: false,
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
              ),
              child: const Center(
                child: Text(
                  'Google AdMob Banner Placeholder',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Goal'),
            content: const Text('This goal will be permanently deleted.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
