import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('SimpleFormatter', () {
    test('formats basic event', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'Svc',
        message: 'Hello',
        timestamp: DateTime(2026, 5, 28, 14, 23, 1),
      );
      final output = const SimpleFormatter(includeTimestamp: false).format(event);
      expect(output, contains('[INFO]'));
      expect(output, contains('Svc »'));
      expect(output, contains('Hello'));
    });

    test('formats event with properties', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'Svc',
        message: 'Order',
        timestamp: DateTime.now(),
        properties: {'orderId': 42},
      );
      final output = const SimpleFormatter(includeTimestamp: false).format(event);
      expect(output, contains('orderId: 42'));
    });

    test('formats event with error', () {
      final event = LogEvent(
        level: PurpleLogLevel.error,
        category: 'Svc',
        message: 'Failed',
        timestamp: DateTime.now(),
        error: Exception('boom'),
      );
      final output = const SimpleFormatter(includeTimestamp: false).format(event);
      expect(output, contains('Error:'));
      expect(output, contains('Exception: boom'));
    });
  });

  group('JsonFormatter', () {
    test('produces valid JSON', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'Svc',
        message: 'Hello',
        timestamp: DateTime(2026, 5, 28),
      );
      final output = const JsonFormatter().format(event);
      expect(output, startsWith('{'));
      expect(output, contains('"level":"info"'));
      expect(output, contains('"category":"Svc"'));
      expect(output, contains('"message":"Hello"'));
    });

    test('includes properties when present', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'Svc',
        message: 'Hello',
        timestamp: DateTime.now(),
        properties: {'key': 'value'},
      );
      final output = const JsonFormatter().format(event);
      expect(output, contains('"properties"'));
      expect(output, contains('"key":"value"'));
    });

    test('omits empty fields', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'Svc',
        message: 'Hello',
        timestamp: DateTime.now(),
      );
      final output = const JsonFormatter().format(event);
      expect(output, isNot(contains('"properties"')));
      expect(output, isNot(contains('"error"')));
    });
  });
}