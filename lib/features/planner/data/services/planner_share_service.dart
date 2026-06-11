/// Formats planner items/plans as readable text and shares via [share_plus].
///
/// Feature-specific service — no UI, no BuildContext.
library;

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerShareService {
  const PlannerShareService();

  static final _dateFmt = DateFormat('EEEE, d MMMM yyyy');
  static final _timeFmt = DateFormat('HH:mm');

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Shares a single planner item as formatted text.
  Future<void> shareItem(PlannerItemEntity item) async {
    final text = _formatItem(item);
    await Share.share(text, subject: item.title);
  }

  /// Shares all items for a single [day] as a text plan.
  Future<void> shareDayPlan(DateTime day, List<PlannerItemEntity> items) async {
    final dayItems = items
        .where((i) => _isSameDay(i.date, day))
        .toList()
      ..sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

    final buffer = StringBuffer();
    buffer.writeln('📅 Day Plan — ${_dateFmt.format(day)}');
    buffer.writeln('─' * 36);

    if (dayItems.isEmpty) {
      buffer.writeln('No plans for this day.');
    } else {
      for (final item in dayItems) {
        buffer.writeln(_formatItem(item));
        buffer.writeln();
      }
    }

    await Share.share(buffer.toString(), subject: 'Day Plan — ${_dateFmt.format(day)}');
  }

  /// Shares all items for a week starting at [weekStart] (Monday).
  Future<void> shareWeekPlan(
    DateTime weekStart,
    List<PlannerItemEntity> items,
  ) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekItems = items
        .where((i) => !i.date.isBefore(weekStart) && !i.date.isAfter(weekEnd))
        .toList()
      ..sort((a, b) {
        final dateCmp = a.date.compareTo(b.date);
        return dateCmp != 0 ? dateCmp : (a.startTime ?? 0).compareTo(b.startTime ?? 0);
      });

    final buffer = StringBuffer();
    buffer.writeln('🗓 Week Plan — ${_dateFmt.format(weekStart)} → ${_dateFmt.format(weekEnd)}');
    buffer.writeln('─' * 36);

    DateTime? lastDay;
    for (final item in weekItems) {
      if (lastDay == null || !_isSameDay(lastDay, item.date)) {
        lastDay = item.date;
        buffer.writeln('\n${_dateFmt.format(item.date)}');
      }
      buffer.writeln(_formatItem(item));
    }

    if (weekItems.isEmpty) buffer.writeln('No plans for this week.');

    await Share.share(
      buffer.toString(),
      subject: 'Week Plan — ${_dateFmt.format(weekStart)}',
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatItem(PlannerItemEntity item) {
    final buffer = StringBuffer();
    final timeStr = _buildTimeString(item);
    buffer.write('${item.type.emoji}  ${item.title}');
    if (timeStr.isNotEmpty) buffer.write('  ·  $timeStr');
    if (item.description.isNotEmpty) buffer.write('\n   ${item.description}');
    if (item.locationOrLink.isNotEmpty) buffer.write('\n   📍 ${item.locationOrLink}');
    buffer.write('\n   [${item.status.displayName}]');
    return buffer.toString();
  }

  String _buildTimeString(PlannerItemEntity item) {
    if (item.isAllDay) return 'All day';
    final start = item.startTime;
    final end = item.endTime;
    if (start == null) return '';
    final startDt = _minutesToDateTime(start);
    if (end == null) return _timeFmt.format(startDt);
    final endDt = _minutesToDateTime(end);
    return '${_timeFmt.format(startDt)} – ${_timeFmt.format(endDt)}';
  }

  DateTime _minutesToDateTime(int minutes) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
