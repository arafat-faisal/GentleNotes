import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/gentle_scaffold.dart';
import 'controllers/goals_controller.dart';
import '../domain/entities/goal_enums.dart';
import 'widgets/goal_card.dart';

class GoalsDashboardScreen extends ConsumerWidget {
  const GoalsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return GentleScaffold(
      title: 'Goals & Priorities',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/goals/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      body: DefaultTabController(
        length: GoalHorizon.values.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: GoalHorizon.values.map((h) => Tab(text: h.displayName)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: GoalHorizon.values.map((horizon) {
                  final horizonGoals = goals.where((g) => g.horizon == horizon).toList();
                  if (horizonGoals.isEmpty) {
                    return const Center(child: Text('No goals here yet.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: horizonGoals.length,
                    itemBuilder: (context, index) {
                      final goal = horizonGoals[index];
                      return GoalCard(
                        goal: goal,
                        onTap: () => context.push('/goals/detail/${goal.id}'),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
