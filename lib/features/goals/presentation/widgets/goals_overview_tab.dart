import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_enums.dart';
import 'goal_card.dart';

class GoalsOverviewTab extends StatelessWidget {
  final List<GoalEntity> goals;

  const GoalsOverviewTab({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
    final achievedGoals = goals.where((g) => g.status == GoalStatus.achieved).toList();
    final failedGoals = goals.where((g) => g.status == GoalStatus.failed).toList();

    final highPriorityActiveGoals = activeGoals.where((g) => g.priority == GoalPriority.high).toList();

    final totalGoalsCount = goals.length;
    final completionRate = totalGoalsCount > 0 
        ? achievedGoals.length / totalGoalsCount 
        : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ── Summary Dashboard Card ──
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.violet, AppColors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goals Progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievedGoals.isNotEmpty 
                              ? 'Keep moving forward!' 
                              : 'Set your targets and priorities.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: completionRate,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          strokeWidth: 5,
                        ),
                      ),
                      Text(
                        '${(completionRate * 100).toInt()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem('Active', activeGoals.length.toString(), theme),
                  _buildMetricDivider(),
                  _buildMetricItem('Achieved', achievedGoals.length.toString(), theme),
                  _buildMetricDivider(),
                  _buildMetricItem('Failed', failedGoals.length.toString(), theme),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Star Focus Section (High Priority Active) ──
        if (highPriorityActiveGoals.isNotEmpty) ...[
          _buildSectionHeader(context, 'Star Focus', Icons.star_rounded, Colors.amber),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: highPriorityActiveGoals.length,
            itemBuilder: (context, index) {
              final goal = highPriorityActiveGoals[index];
              return GoalCard(
                goal: goal,
                onTap: () => context.push('/goals/detail/${goal.id}'),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // ── Horizon Sections ──
        _buildSectionHeader(context, 'Horizon Priorities', Icons.insights_rounded, theme.colorScheme.primary),
        const SizedBox(height: 12),
        ...GoalHorizon.values.map((horizon) {
          final horizonGoals = activeGoals.where((g) => g.horizon == horizon).toList();
          final horizonColor = _getHorizonColor(horizon);
          final icon = _getHorizonIcon(horizon);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: horizonColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: horizonColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              horizon.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${horizonGoals.length} active priority',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final tabController = DefaultTabController.of(context);
                          // Index is horizon.index + 1 because Overview is at index 0
                          tabController.animateTo(horizon.index + 1);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: horizonColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Horizon Goals List
                if (horizonGoals.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: horizonGoals.take(2).length,
                    itemBuilder: (context, index) {
                      final goal = horizonGoals[index];
                      return GoalCard(
                        goal: goal,
                        onTap: () => context.push('/goals/detail/${goal.id}'),
                      );
                    },
                  )
                else
                  _buildEmptyHorizonPlaceholder(context, horizon, horizonColor),
              ],
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHorizonPlaceholder(BuildContext context, GoalHorizon horizon, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: InkWell(
          onTap: () => context.push('/goals/create?horizon=${horizon.name}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a ${horizon.displayName} priority',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define steps to hit milestones',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getHorizonColor(GoalHorizon horizon) {
    switch (horizon) {
      case GoalHorizon.daily:
        return AppColors.rose;
      case GoalHorizon.weekly:
        return AppColors.emerald;
      case GoalHorizon.monthly:
        return AppColors.violet;
      case GoalHorizon.yearly:
        return AppColors.amber;
      case GoalHorizon.lifetime:
        return AppColors.sky;
    }
  }

  IconData _getHorizonIcon(GoalHorizon horizon) {
    switch (horizon) {
      case GoalHorizon.daily:
        return Icons.today_rounded;
      case GoalHorizon.weekly:
        return Icons.date_range_rounded;
      case GoalHorizon.monthly:
        return Icons.calendar_month_rounded;
      case GoalHorizon.yearly:
        return Icons.auto_awesome_mosaic_rounded;
      case GoalHorizon.lifetime:
        return Icons.star_border_rounded;
    }
  }
}
