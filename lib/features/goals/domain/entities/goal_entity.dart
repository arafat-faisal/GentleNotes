library;

import 'goal_enums.dart';

class GoalStepEntity {
  const GoalStepEntity({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final bool isCompleted;

  GoalStepEntity copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return GoalStepEntity(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.horizon,
    this.status = GoalStatus.active,
    this.priority = GoalPriority.medium,
    this.steps = const [],
    this.failureReason = '',
    this.lessonsLearned = '',
    this.relatedNoteIds = const [],
    this.relatedPlannerItemIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.targetDate,
    this.retryOfGoalId,
  });

  final String id;
  final String title;
  final String description;
  final GoalHorizon horizon;
  final GoalStatus status;
  final GoalPriority priority;
  final List<GoalStepEntity> steps;

  final String failureReason;
  final String lessonsLearned;

  final List<String> relatedNoteIds;
  final List<String> relatedPlannerItemIds;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? targetDate;
  
  /// If this goal is a retry of a failed goal, this stores the original goal ID.
  final String? retryOfGoalId;

  int get completedStepsCount => steps.where((s) => s.isCompleted).length;
  int get totalStepsCount => steps.length;
  double get progressPercentage {
    if (steps.isEmpty) {
      return status == GoalStatus.achieved ? 1.0 : 0.0;
    }
    return completedStepsCount / totalStepsCount;
  }

  GoalEntity copyWith({
    String? title,
    String? description,
    GoalHorizon? horizon,
    GoalStatus? status,
    GoalPriority? priority,
    List<GoalStepEntity>? steps,
    String? failureReason,
    String? lessonsLearned,
    List<String>? relatedNoteIds,
    List<String>? relatedPlannerItemIds,
    DateTime? updatedAt,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? retryOfGoalId,
  }) {
    return GoalEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      horizon: horizon ?? this.horizon,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      steps: steps ?? this.steps,
      failureReason: failureReason ?? this.failureReason,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      relatedNoteIds: relatedNoteIds ?? this.relatedNoteIds,
      relatedPlannerItemIds: relatedPlannerItemIds ?? this.relatedPlannerItemIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      retryOfGoalId: retryOfGoalId ?? this.retryOfGoalId,
    );
  }
}
