import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('NullLogger', () {
    test('isEnabled always returns false', () {
      final logger = NullLogger();
      for (final level in PurpleLogLevel.values) {
        expect(logger.isEnabled(level), isFalse);
      }
    });

    test('write does not throw', () {
      final logger = NullLogger();
      expect(
        () => logger.write(LogEvent(
          level: PurpleLogLevel.info,
          category: 'T',
          message: 'm',
          timestamp: DateTime.now(),
        )),
        returnsNormally,
      );
    });
  });

  group('TimestampProvider', () {
    test('utc returns current time', () {
      final before = DateTime.now();
      final result = TimestampProvider.utc.now();
      final after = DateTime.now();
      expect(
          result.isAfter(before.subtract(Duration(milliseconds: 1))), isTrue);
      expect(result.isBefore(after.add(Duration(milliseconds: 1))), isTrue);
    });

    test('fake returns fixed time', () {
      final fixed = DateTime(2026, 1, 1);
      final provider = TimestampProvider.fake(fixed);
      expect(provider.now(), equals(fixed));
    });
  });

  group('PurpleLogger.quick', () {
    tearDown(() => PurpleLogger.disposeQuickFactory());

    test('quick returns a logger', () {
      final logger = PurpleLogger.quick();
      expect(logger, isNotNull);
      expect(logger.category, equals('App'));
    });

    test('quick with custom category', () {
      final logger = PurpleLogger.quick(category: 'Custom');
      expect(logger.category, equals('Custom'));
    });

    test('disposeQuickFactory allows rebuild', () {
      final a = PurpleLogger.quick();
      PurpleLogger.disposeQuickFactory();
      final b = PurpleLogger.quick();
      expect(identical(a, b), isFalse);
    });
  });
}
