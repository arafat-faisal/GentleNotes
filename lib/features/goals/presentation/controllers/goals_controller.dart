library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/goals_storage_impl.dart';
import '../../data/datasources/i_goals_storage.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_enums.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/usecases/goal_usecases.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final goalsStorageProvider = Provider<IGoalsStorage>((ref) {
  final box = Hive.box(AppConstants.goalsBox);
  return GoalsStorageImpl(box);
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final storage = ref.watch(goalsStorageProvider);
  return GoalRepositoryImpl(storage: storage);
});

final goalsProvider = StateNotifierProvider<GoalsController, List<GoalEntity>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  final controller = GoalsController(repository: repository);
  controller.loadGoals();
  return controller;
});

// ── Controller ──────────────────────────────────────────────────────────────

class GoalsController extends StateNotifier<List<GoalEntity>> {
  GoalsController({required this.repository}) : super([]);

  final GoalRepository repository;

  void loadGoals() {
    state = repository.getGoals();
  }

  Future<void> createGoal({
    required String title,
    required String description,
    required GoalHorizon horizon,
    required GoalPriority priority,
    List<GoalStepEntity> steps = const [],
    DateTime? targetDate,
  }) async {
    final useCase = CreateGoalUseCase(repository);
    await useCase(
      title: title,
      description: description,
      horizon: horizon,
      priority: priority,
      steps: steps,
      targetDate: targetDate,
    );
    loadGoals();
  }

  Future<void> updateGoal(GoalEntity goal) async {
    final useCase = UpdateGoalUseCase(repository);
    await useCase(goal);
    loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    final useCase = DeleteGoalUseCase(repository);
    await useCase(id);
    loadGoals();
  }

  Future<void> markAchieved(GoalEntity goal) async {
    final useCase = MarkGoalAchievedUseCase(repository);
    await useCase(goal);
    loadGoals();
  }

  Future<void> failGoal({
    required GoalEntity goal,
    required String failureReason,
    required String lessonsLearned,
  }) async {
    final useCase = FailGoalUseCase(repository);
    await useCase(
      goal: goal,
      failureReason: failureReason,
      lessonsLearned: lessonsLearned,
    );
    loadGoals();
  }

  Future<void> retryGoal(GoalEntity failedGoal) async {
    final useCase = RetryGoalUseCase(repository);
    await useCase(failedGoal);
    loadGoals();
  }

  Future<void> toggleStep(GoalEntity goal, String stepId) async {
    final steps = goal.steps.map((s) {
      if (s.id == stepId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();
    await updateGoal(goal.copyWith(steps: steps));
  }
}
