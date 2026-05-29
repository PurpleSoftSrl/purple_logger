import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('LogEvent', () {
    test('creates with required fields', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'Test',
        message: 'Hello',
        timestamp: DateTime(2026, 5, 28),
      );
      expect(event.level, equals(PurpleLogLevel.info));
      expect(event.category, equals('Test'));
      expect(event.message, equals('Hello'));
      expect(event.properties, isEmpty);
      expect(event.scopeProperties, isEmpty);
      expect(event.error, isNull);
      expect(event.stackTrace, isNull);
    });

    test('creates with all fields', () {
      final ts = DateTime(2026, 5, 28);
      final event = LogEvent(
        level: PurpleLogLevel.error,
        category: 'Svc',
        message: 'Failed',
        timestamp: ts,
        properties: {'key': 'value'},
        scopeProperties: {'requestId': 'abc'},
        error: Exception('boom'),
        stackTrace: StackTrace.current,
      );
      expect(event.properties['key'], equals('value'));
      expect(event.scopeProperties['requestId'], equals('abc'));
      expect(event.error, isNotNull);
    });

    test('properties are immutable', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'T',
        message: 'm',
        timestamp: DateTime.now(),
        properties: {'k': 'v'},
      );
      expect(() => (event.properties as Map)['k'] = 'x', throwsA(anything));
    });

    test('copyWith overrides fields', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'A',
        message: 'm',
        timestamp: DateTime(2026, 1, 1),
      );
      final copy = event.copyWith(level: PurpleLogLevel.error, message: 'new');
      expect(copy.level, equals(PurpleLogLevel.error));
      expect(copy.message, equals('new'));
      expect(copy.category, equals('A')); // unchanged
    });

    test('equality works', () {
      final ts = DateTime(2026, 5, 28);
      final a = LogEvent(
        level: PurpleLogLevel.info,
        category: 'T',
        message: 'm',
        timestamp: ts,
      );
      final b = LogEvent(
        level: PurpleLogLevel.info,
        category: 'T',
        message: 'm',
        timestamp: ts,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
