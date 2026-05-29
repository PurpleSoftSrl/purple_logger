import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('PurpleLogLevel', () {
    test('ordering is correct', () {
      expect(PurpleLogLevel.trace.index, lessThan(PurpleLogLevel.debug.index));
      expect(PurpleLogLevel.debug.index, lessThan(PurpleLogLevel.info.index));
      expect(PurpleLogLevel.info.index, lessThan(PurpleLogLevel.warning.index));
      expect(
          PurpleLogLevel.warning.index, lessThan(PurpleLogLevel.error.index));
      expect(PurpleLogLevel.error.index, lessThan(PurpleLogLevel.fatal.index));
      expect(PurpleLogLevel.fatal.index, lessThan(PurpleLogLevel.none.index));
    });

    test('isAtLeast works correctly', () {
      expect(PurpleLogLevel.warning.isAtLeast(PurpleLogLevel.info), isTrue);
      expect(PurpleLogLevel.info.isAtLeast(PurpleLogLevel.warning), isFalse);
      expect(PurpleLogLevel.trace.isAtLeast(PurpleLogLevel.trace), isTrue);
      expect(PurpleLogLevel.none.isAtLeast(PurpleLogLevel.trace), isFalse);
    });

    test('isNone works correctly', () {
      expect(PurpleLogLevel.none.isNone, isTrue);
      expect(PurpleLogLevel.trace.isNone, isFalse);
    });

    test('severityNumber maps to OTel spec', () {
      expect(PurpleLogLevel.trace.severityNumber, equals(1));
      expect(PurpleLogLevel.debug.severityNumber, equals(5));
      expect(PurpleLogLevel.info.severityNumber, equals(9));
      expect(PurpleLogLevel.warning.severityNumber, equals(13));
      expect(PurpleLogLevel.error.severityNumber, equals(17));
      expect(PurpleLogLevel.fatal.severityNumber, equals(21));
      expect(PurpleLogLevel.none.severityNumber, equals(0));
    });

    test('severityText matches OTel spec', () {
      expect(PurpleLogLevel.trace.severityText, equals('TRACE'));
      expect(PurpleLogLevel.debug.severityText, equals('DEBUG'));
      expect(PurpleLogLevel.info.severityText, equals('INFO'));
      expect(PurpleLogLevel.warning.severityText, equals('WARN'));
      expect(PurpleLogLevel.error.severityText, equals('ERROR'));
      expect(PurpleLogLevel.fatal.severityText, equals('FATAL'));
      expect(PurpleLogLevel.none.severityText, equals(''));
    });

    test('labels are 4 chars', () {
      for (final level in PurpleLogLevel.values) {
        if (level != PurpleLogLevel.none) {
          expect(level.label.length, equals(4));
        }
      }
    });
  });
}
