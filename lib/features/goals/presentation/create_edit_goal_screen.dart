import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/widgets/gentle_scaffold.dart';
import '../domain/entities/goal_entity.dart';
import '../domain/entities/goal_enums.dart';
import 'controllers/goals_controller.dart';

class CreateEditGoalScreen extends ConsumerStatefulWidget {
  final String? goalId;

  const CreateEditGoalScreen({super.key, this.goalId});

  @override
  ConsumerState<CreateEditGoalScreen> createState() => _CreateEditGoalScreenState();
}

class _CreateEditGoalScreenState extends ConsumerState<CreateEditGoalScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  GoalHorizon _horizon = GoalHorizon.weekly;
  GoalPriority _priority = GoalPriority.medium;
  final List<GoalStepEntity> _steps = [];
  final _stepController = TextEditingController();

  GoalEntity? _existingGoal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.goalId != null) {
        final goals = ref.read(goalsProvider);
        try {
          final goal = goals.firstWhere((g) => g.id == widget.goalId);
          _existingGoal = goal;
          setState(() {
            _titleController.text = goal.title;
            _descController.text = goal.description;
            _horizon = goal.horizon;
            _priority = goal.priority;
            _steps.addAll(goal.steps);
          });
        } catch (_) {
          context.pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _addStep() {
    final title = _stepController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _steps.add(GoalStepEntity(id: const Uuid().v4(), title: title));
      });
      _stepController.clear();
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final existingGoal = _existingGoal;
    if (existingGoal == null) {
      await ref.read(goalsProvider.notifier).createGoal(
        title: title,
        description: _descController.text.trim(),
        horizon: _horizon,
        priority: _priority,
        steps: _steps,
      );
    } else {
      await ref.read(goalsProvider.notifier).updateGoal(
        existingGoal.copyWith(
          title: title,
          description: _descController.text.trim(),
          horizon: _horizon,
          priority: _priority,
          steps: _steps,
        ),
      );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return GentleScaffold(
      title: _existingGoal == null ? 'New Goal' : 'Edit Goal',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _save,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GoalHorizon>(
              value: _horizon,
              decoration: const InputDecoration(
                labelText: 'Horizon',
                border: OutlineInputBorder(),
              ),
              items: GoalHorizon.values.map((h) {
                return DropdownMenuItem(value: h, child: Text(h.displayName));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _horizon = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GoalPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: GoalPriority.values.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _priority = val);
              },
            ),
            const SizedBox(height: 24),
            Text('Steps', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._steps.asMap().entries.map((entry) {
              final step = entry.value;
              final index = entry.key;
              return ListTile(
                title: Text(step.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _steps.removeAt(index);
                    });
                  },
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: const InputDecoration(
                      hintText: 'Add a step...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addStep,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
