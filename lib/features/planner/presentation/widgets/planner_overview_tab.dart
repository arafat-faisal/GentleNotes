import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/planner_enums.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../controllers/planner_controller.dart';
import '../screens/create_edit_planner_item_screen.dart';
import 'planner_item_card.dart';

class PlannerOverviewTab extends ConsumerWidget {
  final TabController tabController;

  const PlannerOverviewTab({super.key, required this.tabController});

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _isThisWeek(DateTime date, DateTime now) {
    if (_isSameDay(date, now)) return false;
    final diff = date.difference(now).inDays;
    return diff >= 0 && diff < 7;
  }

  bool _isThisMonth(DateTime date, DateTime now) {
    return date.year == now.year && date.month == now.month && !_isSameDay(date, now) && !_isThisWeek(date, now);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final plannerState = ref.watch(plannerProvider);
    final controller = ref.read(plannerProvider.notifier);
    final now = DateTime.now();

    final allItems = plannerState.items;
    
    // Sort all upcoming or current items (ignoring past completed items for overview simplicity)
    final activeItems = allItems.where((item) {
      if (item.status == PlannerStatus.cancelled) return false;
      // Keep today's items (even if completed, for rate stats)
      if (_isSameDay(item.date, now)) return true;
      // Keep upcoming items
      return item.date.isAfter(now);
    }).toList();

    // Grouping
    final todayItems = activeItems.where((item) => _isSameDay(item.date, now)).toList();
    final todayCompleted = todayItems.where((item) => item.isCompleted).toList();
    
    final weekItems = activeItems.where((item) => _isThisWeek(item.date, now) && !item.isCompleted).toList();
    final monthItems = activeItems.where((item) => _isThisMonth(item.date, now) && !item.isCompleted).toList();
    
    final highPriorityItems = activeItems.where((item) => item.priority == PlannerPriority.high && !item.isCompleted).toList();

    final todayCompletionRate = todayItems.isNotEmpty
        ? todayCompleted.length / todayItems.length
        : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ── Summary Dashboard Card ──
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.indigo, AppColors.violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: 0.3),
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
                          "Today's Overview",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todayItems.isEmpty
                              ? 'No plans set for today.'
                              : todayCompletionRate == 1.0
                                  ? 'All completed! Fantastic job!'
                                  : 'Finish today\'s agenda.',
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
                          value: todayCompletionRate,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          strokeWidth: 5,
                        ),
                      ),
                      Text(
                        '${(todayCompletionRate * 100).toInt()}%',
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
                  _buildMetricItem("Today's Plans", todayItems.length.toString(), theme),
                  _buildMetricDivider(),
                  _buildMetricItem('High Priority', highPriorityItems.length.toString(), theme),
                  _buildMetricDivider(),
                  _buildMetricItem('Upcoming Total', activeItems.where((i) => !i.isCompleted).length.toString(), theme),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Star Focus Section (High Priority Active) ──
        if (highPriorityItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Star Priorities', Icons.star_rounded, Colors.amber),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: highPriorityItems.length,
            itemBuilder: (context, index) {
              final item = highPriorityItems[index];
              return PlannerItemCard(
                item: item,
                onTap: () => context.push('/planner/item/${item.id}'),
                onComplete: () => controller.markCompleted(item.id),
                showDate: true,
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // ── Timeline Breakdown Sections ──
        _buildSectionHeader(context, 'Agenda Schedules', Icons.calendar_today_rounded, theme.colorScheme.primary),
        const SizedBox(height: 12),

        // 1. TODAY SECTION
        _buildTimelineSection(
          context: context,
          title: 'Today\'s Agenda',
          subtitle: '${todayItems.where((i) => !i.isCompleted).length} pending plans',
          icon: Icons.today_rounded,
          color: AppColors.rose,
          items: todayItems,
          tabIndex: 1,
          placeholderText: 'No plans set for today',
          controller: controller,
          initialDate: now,
        ),

        // 2. THIS WEEK SECTION
        _buildTimelineSection(
          context: context,
          title: 'This Week\'s Horizon',
          subtitle: '${weekItems.length} active plans',
          icon: Icons.date_range_rounded,
          color: AppColors.emerald,
          items: weekItems,
          tabIndex: 2,
          placeholderText: 'No plans set for this week',
          controller: controller,
          initialDate: now.add(const Duration(days: 1)),
        ),

        // 3. THIS MONTH SECTION
        _buildTimelineSection(
          context: context,
          title: 'This Month\'s Focus',
          subtitle: '${monthItems.length} active plans',
          icon: Icons.calendar_month_rounded,
          color: AppColors.violet,
          items: monthItems,
          tabIndex: 3,
          placeholderText: 'No plans set for this month',
          controller: controller,
          initialDate: DateTime(now.year, now.month + 1, 1),
        ),

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

  Widget _buildTimelineSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<PlannerItemEntity> items,
    required int tabIndex,
    required String placeholderText,
    required PlannerController controller,
    required DateTime initialDate,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => tabController.animateTo(tabIndex),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: color,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Goals List
          if (items.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: items.take(2).length,
              itemBuilder: (context, index) {
                final item = items[index];
                return PlannerItemCard(
                  item: item,
                  onTap: () => context.push('/planner/item/${item.id}'),
                  onComplete: () => controller.markCompleted(item.id),
                  showDate: true,
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateEditPlannerItemScreen(initialDate: initialDate),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
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
                          'Add a plan',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          placeholderText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
