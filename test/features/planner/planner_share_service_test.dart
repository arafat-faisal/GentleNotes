import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/features/planner/data/services/planner_share_service.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_enums.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_item_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channels = [
    MethodChannel('dev.fluttercommunity.plus/share'),
    MethodChannel('plugins.flutter.io/share'),
  ];
  final List<MethodCall> methodCalls = <MethodCall>[];

  setUp(() {
    methodCalls.clear();
    for (final channel in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });
    }
  });

  tearDown(() {
    for (final channel in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  group('PlannerShareService Tests', () {
    const shareService = PlannerShareService();
    final now = DateTime.now();
    final itemDate = DateTime(2026, 6, 15);

    final testItem = PlannerItemEntity(
      id: 'item-1',
      title: 'Study Flutter',
      description: 'Clean Architecture logic',
      type: PlannerItemType.studySession,
      date: itemDate,
      startTime: 600, // 10:00
      endTime: 720,   // 12:00
      isAllDay: false,
      locationOrLink: 'Zoom link',
      status: PlannerStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    );

    test('shareItem should format single item and trigger share channel', () async {
      await shareService.shareItem(testItem);

      expect(methodCalls.length, 1);
      final call = methodCalls.first;
      expect(call.method, 'share');
      
      final textArg = call.arguments['text'] as String;
      expect(textArg, contains('📚  Study Flutter'));
      expect(textArg, contains('10:00 – 12:00'));
      expect(textArg, contains('Clean Architecture logic'));
      expect(textArg, contains('📍 Zoom link'));
      expect(textArg, contains('[Upcoming]'));
    });

    test('shareDayPlan should filter, sort by start time, and format day plans', () async {
      final item2 = PlannerItemEntity(
        id: 'item-2',
        title: 'Meeting with Devs',
        description: 'Sync up',
        type: PlannerItemType.meeting,
        date: itemDate,
        startTime: 540, // 09:00 (starts before item-1)
        endTime: 600,
        createdAt: now,
        updatedAt: now,
      );
      final otherDayItem = PlannerItemEntity(
        id: 'item-3',
        title: 'Other Day Item',
        type: PlannerItemType.task,
        date: DateTime(2026, 6, 16), // Different day
        createdAt: now,
        updatedAt: now,
      );

      await shareService.shareDayPlan(
        itemDate,
        [testItem, item2, otherDayItem],
      );

      expect(methodCalls.length, 1);
      final textArg = methodCalls.first.arguments['text'] as String;

      expect(textArg, contains('Day Plan — Monday, 15 June 2026'));
      // Meeting with Devs (09:00) should appear before Study Flutter (10:00)
      final meetingIdx = textArg.indexOf('Meeting with Devs');
      final studyIdx = textArg.indexOf('Study Flutter');
      expect(meetingIdx, isNot(-1));
      expect(studyIdx, isNot(-1));
      expect(meetingIdx, lessThan(studyIdx));
      // otherDayItem should not be in this text
      expect(textArg, isNot(contains('Other Day Item')));
    });

    test('shareWeekPlan should group, sort, and share weekly items', () async {
      // 15 June 2026 is a Monday.
      final monday = DateTime(2026, 6, 15);
      final wednesday = DateTime(2026, 6, 17);
      
      final wednesdayItem = PlannerItemEntity(
        id: 'item-wed',
        title: 'Midweek sync',
        type: PlannerItemType.meeting,
        date: wednesday,
        startTime: 500,
        createdAt: now,
        updatedAt: now,
      );
      
      final nextWeekItem = PlannerItemEntity(
        id: 'item-next-week',
        title: 'Next Week Item',
        type: PlannerItemType.task,
        date: DateTime(2026, 6, 23), // Tuesday next week
        createdAt: now,
        updatedAt: now,
      );

      await shareService.shareWeekPlan(
        monday,
        [testItem, wednesdayItem, nextWeekItem],
      );

      expect(methodCalls.length, 1);
      final textArg = methodCalls.first.arguments['text'] as String;

      expect(textArg, contains('Week Plan — Monday, 15 June 2026'));
      expect(textArg, contains('Study Flutter'));
      expect(textArg, contains('Midweek sync'));
      expect(textArg, isNot(contains('Next Week Item')));
    });
  });
}
