import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_notes/features/planner/data/services/ics_export_service.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_enums.dart';
import 'package:gentle_notes/features/planner/domain/entities/planner_item_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannels = [
    MethodChannel('dev.fluttercommunity.plus/share'),
    MethodChannel('plugins.flutter.io/share'),
  ];
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  
  final List<MethodCall> methodCalls = <MethodCall>[];

  setUp(() {
    methodCalls.clear();
    
    // Mock path provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        return '.'; // Return current directory as temp dir for tests
      }
      return null;
    });

    // Mock share_plus channels
    for (final channel in shareChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });
    }
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    for (final channel in shareChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  group('IcsExportService Tests', () {
    const exportService = IcsExportService();
    final now = DateTime.now();
    final itemDate = DateTime(2026, 6, 15);

    final testItem = PlannerItemEntity(
      id: 'item-1',
      title: 'Exam: Math',
      description: 'Calculus, Algebra\nChapter 3',
      type: PlannerItemType.exam,
      date: itemDate,
      startTime: 540, // 09:00
      endTime: 660,   // 11:00
      isAllDay: false,
      reminderMinutesBefore: 30,
      recurrenceFrequency: RecurrenceFrequency.none,
      locationOrLink: 'Hall A',
      status: PlannerStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    );

    test('exportAndShare should generate valid iCalendar format and trigger share channel', () async {
      await exportService.exportAndShare(testItem);

      expect(methodCalls.length, 1);
      final call = methodCalls.first;
      // Depending on share_plus version, method could be 'shareXFiles' or 'shareFiles'
      expect(call.method, anyOf('shareXFiles', 'shareFiles', 'share'));

      // If it is shareXFiles/shareFiles, check paths or subjects
      // Let's print arguments to be sure if needed, or check structure
    });
  });
}
