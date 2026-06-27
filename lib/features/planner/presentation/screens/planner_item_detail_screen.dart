/// Detail screen for a single planner item.
///
/// Shows full information and exposes Edit, Complete, Share, Export ICS, Delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/planner_controller.dart';
import '../screens/create_edit_planner_item_screen.dart';
import '../widgets/planner_type_chip.dart';
import '../widgets/planner_reschedule_sheet.dart';
import '../../../../features/goals/presentation/controllers/goals_controller.dart';
import '../../data/services/ics_export_service.dart';
import '../../data/services/planner_share_service.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerItemDetailScreen extends ConsumerWidget {
  const PlannerItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  static final _dateFmt = DateFormat('EEEE, d MMMM yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(plannerProvider).items;
    final item = items.where((i) => i.id == itemId).cast<PlannerItemEntity?>().firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan')),
        body: const Center(child: Text('Plan not found.')),
      );
    }

    final theme = Theme.of(context);
    final accentColor = _hexToColor(item.colorHex);

    final goals = ref.watch(goalsProvider);
    final linkedGoal = item.linkedGoalId != null 
        ? goals.where((g) => g.id == item.linkedGoalId).firstOrNull 
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CreateEditPlannerItemScreen(existingItem: item)),
            ),
          ),
          PopupMenuButton<_Action>(
            onSelected: (action) => _handleAction(context, ref, item, action),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Action.complete, child: Text('Mark Complete')),
              PopupMenuItem(value: _Action.share, child: Text('Share')),
              PopupMenuItem(value: _Action.exportIcs, child: Text('Export ICS')),
              PopupMenuItem(value: _Action.delete, child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              )),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Color accent header ──
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Text(
            item.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          // ── Type + Status row ──
          Row(
            children: [
              PlannerTypeChip(type: item.type),
              const SizedBox(width: 10),
              _StatusBadge(status: item.status.displayName, isDone: item.isCompleted),
            ],
          ),
          const SizedBox(height: 20),

          // ── Info rows ──
          _InfoRow(icon: Icons.calendar_today_outlined, label: _dateFmt.format(item.date)),
          if (item.isAllDay)
            const _InfoRow(icon: Icons.wb_sunny_outlined, label: 'All day')
          else if (item.startTime != null)
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: _buildTimeStr(item),
            ),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: '${item.priority.displayName} priority',
          ),
          if (item.isRecurring)
            _InfoRow(
              icon: Icons.repeat_rounded,
              label: item.recurrenceFrequency.displayName,
            ),
          if (item.hasReminder)
            _InfoRow(
              icon: Icons.alarm_outlined,
              label: '${item.reminderMinutesBefore} min reminder',
            ),
          if (item.locationOrLink.isNotEmpty)
            _InfoRow(icon: Icons.place_outlined, label: item.locationOrLink),
          if (item.linkedNoteId != null)
            _InfoRow(icon: Icons.link_rounded, label: 'Note linked'),
          if (linkedGoal != null)
            _GoalLinkBadge(
              goalTitle: linkedGoal.title,
              onTap: () => context.push('/goals/detail/${linkedGoal.id}'),
            ),

          // ── Description ──
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Description', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(item.description, style: theme.textTheme.bodyMedium),
          ],

          // ── Reschedule History ──
          if (item.rescheduleReason.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Reschedule History',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.rescheduleReason,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          // ── Action buttons ──
          if (!item.isCompleted)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReschedule(context, ref, item),
                    icon: const Icon(Icons.sync_alt_rounded),
                    label: const Text('Shift Plan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handleAction(context, ref, item, _Action.complete),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Complete'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _handleReschedule(BuildContext context, WidgetRef ref, PlannerItemEntity item) {
    PlannerRescheduleSheet.show(
      context: context,
      item: item,
      onReschedule: (newDate, newStart, newEnd, isAllDay, reason) async {
        final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
        final newLogEntry = '$dateStr: Shifted to ${_dateFmt.format(newDate)} — "$reason"';
        final updatedReasonLog = item.rescheduleReason.isEmpty
            ? newLogEntry
            : '${item.rescheduleReason}\n$newLogEntry';

        final updatedItem = item.copyWith(
          date: newDate,
          startTime: newStart,
          endTime: newEnd,
          isAllDay: isAllDay,
          rescheduleReason: updatedReasonLog,
          updatedAt: DateTime.now(),
        );

        await ref.read(plannerProvider.notifier).updateItem(updatedItem);
      },
    );
  }

  String _buildTimeStr(PlannerItemEntity item) {
    final now = DateTime.now();
    final start = item.startTime!;
    final startDt = DateTime(now.year, now.month, now.day, start ~/ 60, start % 60);
    if (item.endTime == null) return _timeFmt.format(startDt);
    final endDt = DateTime(now.year, now.month, now.day, item.endTime! ~/ 60, item.endTime! % 60);
    return '${_timeFmt.format(startDt)} – ${_timeFmt.format(endDt)}';
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    PlannerItemEntity item,
    _Action action,
  ) async {
    if (action == _Action.complete) {
      await ref.read(plannerProvider.notifier).markCompleted(item.id);
    } else if (action == _Action.share) {
      await const PlannerShareService().shareItem(item);
    } else if (action == _Action.exportIcs) {
      await const IcsExportService().exportAndShare(item);
    } else if (action == _Action.delete) {
      if (!context.mounted) return;
      final confirmed = await _confirmDelete(context);
      if (confirmed && context.mounted) {
        await ref.read(plannerProvider.notifier).deleteItem(item.id);
        if (context.mounted) context.pop();
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Plan'),
            content: const Text('This plan will be permanently deleted.'),
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

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

enum _Action { complete, share, exportIcs, delete }

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isDone});
  final String status;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? const Color(0xFF10B981) : const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _GoalLinkBadge extends StatelessWidget {
  const _GoalLinkBadge({required this.goalTitle, required this.onTap});
  final String goalTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Goal: $goalTitle',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
