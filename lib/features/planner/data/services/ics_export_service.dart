/// Exports planner items as .ics (iCalendar) files and shares them.
///
/// Produces a minimal VCALENDAR with VEVENT entries.
/// Uses RRULE for recurring items and VALARM for reminders.
/// Shares the file via [share_plus].
library;

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/planner_enums.dart';
import '../../domain/entities/planner_item_entity.dart';

class IcsExportService {
  const IcsExportService();

  static final _icsDateFmt = DateFormat("yyyyMMdd'T'HHmmss");
  static final _icsDateOnlyFmt = DateFormat('yyyyMMdd');

  /// Exports a single [item] to a .ics file and shares it.
  Future<void> exportAndShare(PlannerItemEntity item) async {
    final content = _buildCalendar([item]);
    await _writeAndShare(content, fileName: '${_sanitize(item.title)}.ics');
  }

  /// Exports multiple [items] to a .ics file and shares it.
  Future<void> exportListAndShare(
    List<PlannerItemEntity> items, {
    String fileName = 'gentle_planner.ics',
  }) async {
    final content = _buildCalendar(items);
    await _writeAndShare(content, fileName: fileName);
  }

  // ── iCalendar Building ───────────────────────────────────────────────────────

  String _buildCalendar(List<PlannerItemEntity> items) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//GentleNotes//Gentle Planner//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    for (final item in items) {
      buffer.write(_buildEvent(item));
    }
    buffer.write('END:VCALENDAR');
    return buffer.toString();
  }

  String _buildEvent(PlannerItemEntity item) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${item.id}@gentlenotes');
    buffer.writeln('DTSTAMP:${_icsDateFmt.format(now)}');

    if (item.isAllDay) {
      buffer.writeln('DTSTART;VALUE=DATE:${_icsDateOnlyFmt.format(item.date)}');
      buffer.writeln(
          'DTEND;VALUE=DATE:${_icsDateOnlyFmt.format(item.date.add(const Duration(days: 1)))}');
    } else {
      final start = _toDateTime(item.date, item.startTime);
      final end = _toDateTime(item.date, item.endTime ?? (item.startTime ?? 0) + 60);
      buffer.writeln('DTSTART:${_icsDateFmt.format(start)}');
      buffer.writeln('DTEND:${_icsDateFmt.format(end)}');
    }

    buffer.writeln('SUMMARY:${_escapeText(item.title)}');
    if (item.description.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${_escapeText(item.description)}');
    }
    if (item.locationOrLink.isNotEmpty) {
      buffer.writeln('LOCATION:${_escapeText(item.locationOrLink)}');
    }
    buffer.writeln('PRIORITY:${_priorityValue(item.priority)}');

    // Recurrence rule.
    final rrule = _buildRRule(item.recurrenceFrequency);
    if (rrule.isNotEmpty) buffer.writeln('RRULE:$rrule');

    // Alarm (VALARM) for reminder.
    if (item.hasReminder && item.reminderMinutesBefore != null) {
      buffer.writeln('BEGIN:VALARM');
      buffer.writeln('TRIGGER:-PT${item.reminderMinutesBefore}M');
      buffer.writeln('ACTION:DISPLAY');
      buffer.writeln('DESCRIPTION:Reminder for ${item.title}');
      buffer.writeln('END:VALARM');
    }

    buffer.writeln('END:VEVENT');
    return buffer.toString();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _buildRRule(RecurrenceFrequency freq) {
    switch (freq) {
      case RecurrenceFrequency.daily:   return 'FREQ=DAILY';
      case RecurrenceFrequency.weekly:  return 'FREQ=WEEKLY';
      case RecurrenceFrequency.monthly: return 'FREQ=MONTHLY';
      case RecurrenceFrequency.none:    return '';
    }
  }

  int _priorityValue(PlannerPriority p) {
    switch (p) {
      case PlannerPriority.high:   return 1;
      case PlannerPriority.medium: return 5;
      case PlannerPriority.low:    return 9;
    }
  }

  DateTime _toDateTime(DateTime date, int? minutesSinceMidnight) {
    final m = minutesSinceMidnight ?? 0;
    return DateTime(date.year, date.month, date.day, m ~/ 60, m % 60);
  }

  String _escapeText(String text) =>
      text.replaceAll('\\', '\\\\').replaceAll('\n', '\\n').replaceAll(',', '\\,');

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');

  Future<void> _writeAndShare(String content, {required String fileName}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/calendar')],
      subject: fileName,
    );
  }
}
