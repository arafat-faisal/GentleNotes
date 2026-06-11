import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI Import Parser Tests', () {
    String sanitizeJson(String rawText) {
      var s = rawText.trim();
      if (s.contains('```')) {
        final startIdx = s.indexOf('[');
        final endIdx = s.lastIndexOf(']');
        if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
          s = s.substring(startIdx, endIdx + 1);
        }
      }
      return s;
    }

    test('should parse standard clean JSON array', () {
      const input = '''
[
  {
    "title": "Read Chapter 1",
    "date": "2026-06-12",
    "type": "studySession"
  }
]
''';
      final sanitized = sanitizeJson(input);
      final decoded = jsonDecode(sanitized) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['title'], 'Read Chapter 1');
      expect(decoded[0]['date'], '2026-06-12');
    });

    test('should strip markdown code blocks and parse correctly', () {
      const input = '''
Here is your reading schedule:
```json
[
  {
    "title": "Read Chapter 2",
    "date": "2026-06-13",
    "type": "studySession"
  }
]
```
I hope this helps!
''';
      final sanitized = sanitizeJson(input);
      final decoded = jsonDecode(sanitized) as List;
      expect(decoded.length, 1);
      expect(decoded[0]['title'], 'Read Chapter 2');
      expect(decoded[0]['date'], '2026-06-13');
    });

    test('should fail parsing if brackets are missing', () {
      const input = '{"title": "Not an array"}';
      final sanitized = sanitizeJson(input);
      final decoded = jsonDecode(sanitized);
      expect(decoded, isNot(isList));
    });
  });
}
