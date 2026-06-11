/// Enums for the Planner feature.
///
/// Kept in a dedicated file so domain entities, data models, and UI can all
/// import a single source of truth without pulling in unrelated code.
library;

enum PlannerItemType {
  task,
  meeting,
  studySession,
  exam,
  deadline,
  habit;

  String get displayName {
    switch (this) {
      case PlannerItemType.task:         return 'Task';
      case PlannerItemType.meeting:      return 'Meeting';
      case PlannerItemType.studySession: return 'Study Session';
      case PlannerItemType.exam:         return 'Exam';
      case PlannerItemType.deadline:     return 'Deadline';
      case PlannerItemType.habit:        return 'Habit';
    }
  }

  String get emoji {
    switch (this) {
      case PlannerItemType.task:         return '✅';
      case PlannerItemType.meeting:      return '🤝';
      case PlannerItemType.studySession: return '📚';
      case PlannerItemType.exam:         return '📝';
      case PlannerItemType.deadline:     return '⏰';
      case PlannerItemType.habit:        return '🔁';
    }
  }
}

enum PlannerPriority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case PlannerPriority.low:    return 'Low';
      case PlannerPriority.medium: return 'Medium';
      case PlannerPriority.high:   return 'High';
    }
  }
}

enum PlannerStatus {
  upcoming,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case PlannerStatus.upcoming:   return 'Upcoming';
      case PlannerStatus.inProgress: return 'In Progress';
      case PlannerStatus.completed:  return 'Completed';
      case PlannerStatus.cancelled:  return 'Cancelled';
    }
  }

  bool get isDone => this == PlannerStatus.completed || this == PlannerStatus.cancelled;
}

enum RecurrenceFrequency {
  none,
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.none:    return 'No Repeat';
      case RecurrenceFrequency.daily:   return 'Daily';
      case RecurrenceFrequency.weekly:  return 'Weekly';
      case RecurrenceFrequency.monthly: return 'Monthly';
    }
  }
}
