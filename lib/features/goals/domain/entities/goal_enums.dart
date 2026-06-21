library;

enum GoalHorizon {
  daily,
  weekly,
  monthly,
  yearly,
  lifetime;

  String get displayName {
    switch (this) {
      case GoalHorizon.daily: return 'Daily';
      case GoalHorizon.weekly: return 'Weekly';
      case GoalHorizon.monthly: return 'Monthly';
      case GoalHorizon.yearly: return 'Yearly';
      case GoalHorizon.lifetime: return 'Lifetime';
    }
  }
}

enum GoalStatus {
  active,
  achieved,
  failed,
  retried;
}

enum GoalPriority {
  low,
  medium,
  high;
}
