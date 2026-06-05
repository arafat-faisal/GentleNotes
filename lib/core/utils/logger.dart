import 'package:flutter/foundation.dart';

/// A simple, unified logging utility for GentleNotes that works across all platforms.
/// Stores logs in memory for debugging and diagnostic exports, and prints to console.
class AppLogger {
  static final List<String> _logs = [];

  static List<String> get logs => List.unmodifiable(_logs);

  static void info(String message) {
    _log('INFO', message);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('WARNING', message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  static void _log(String level, String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [$level] $message';
    _logs.add(logLine);
    debugPrint(logLine);

    if (error != null) {
      final errLine = '  └─ Error: $error';
      _logs.add(errLine);
      debugPrint(errLine);
    }
    if (stackTrace != null) {
      final stackLine = '  └─ StackTrace:\n$stackTrace';
      _logs.add(stackLine);
      debugPrint(stackLine);
    }

    // Keep logs list at a reasonable size in memory
    if (_logs.length > 1000) {
      _logs.removeRange(0, 200);
    }
  }

  static void clear() {
    _logs.clear();
  }

  static String exportLogs() {
    return _logs.join('\n');
  }
}
