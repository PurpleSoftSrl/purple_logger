import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('PurpleLogger', () {
    test('creates named logger', () {
      final log = PurpleLogger('TestPlugin');
      expect(log, isNotNull);
    });

    test('creates child logger', () {
      final log = PurpleLogger('TestPlugin');
      final child = log.child('SubComponent');
      expect(child, isNotNull);
    });

    test('logs at all levels without throwing', () {
      final log = PurpleLogger('TestPlugin');
      // Should not throw
      log.finest('finest message');
      log.finer('finer message');
      log.fine('fine message');
      log.config('config message');
      log.info('info message');
      log.warning('warning message');
      log.error('error message');
      log.critical('critical message');
    });

    test('logs with error and stackTrace', () {
      final log = PurpleLogger('TestPlugin');
      try {
        throw StateError('test error');
      } catch (e, st) {
        // Should not throw
        log.error('caught error', e, st);
      }
    });
  });
}