import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('LoggerFactory', () {
    late MemoryLogStore store;
    late LoggerFactory factory;

    setUp(() {
      store = MemoryLogStore();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
    });

    tearDown(() => factory.dispose());

    test('createLogger returns Logger with correct category', () {
      final logger = factory.createLogger('Test');
      expect(logger.category, equals('Test'));
    });

    test('same category returns same logger instance', () {
      final a = factory.createLogger('Svc');
      final b = factory.createLogger('Svc');
      expect(identical(a, b), isTrue);
    });

    test('different categories return different loggers', () {
      final a = factory.createLogger('A');
      final b = factory.createLogger('B');
      expect(identical(a, b), isFalse);
    });

    test('isEnabled respects minimum level', () {
      factory.dispose();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.warning)
          .build();
      final logger = factory.createLogger('Svc');
      expect(logger.isEnabled(PurpleLogLevel.info), isFalse);
      expect(logger.isEnabled(PurpleLogLevel.warning), isTrue);
    });

    test('dispose throws on subsequent use', () {
      factory.dispose();
      expect(() => factory.createLogger('X'), throwsStateError);
    });
  });

  group('Logger', () {
    late MemoryLogStore store;
    late LoggerFactory factory;
    late Logger logger;

    setUp(() {
      store = MemoryLogStore();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      logger = factory.createLogger('TestService');
    });

    tearDown(() => factory.dispose());

    test('info logs at INFO level', () {
      logger.info('Hello');
      expect(store.length, equals(1));
      expect(store.events.first.level, equals(PurpleLogLevel.info));
      expect(store.events.first.message, equals('Hello'));
      expect(store.events.first.category, equals('TestService'));
    });

    test('structured properties are preserved', () {
      logger.info('Order placed', properties: {'orderId': 1042});
      final event = store.events.first;
      expect(event.properties['orderId'], equals(1042));
    });

    test('error logs with error and stackTrace', () {
      final err = Exception('boom');
      final st = StackTrace.current;
      logger.error('Failed', error: err, stackTrace: st);
      final event = store.events.first;
      expect(event.level, equals(PurpleLogLevel.error));
      expect(event.error, equals(err));
      expect(event.stackTrace, equals(st));
    });

    test('zero-alloc guard: disabled level produces no event', () {
      factory.dispose();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.warning)
          .build();
      final filteredLogger = factory.createLogger('Svc');
      store.clear();
      filteredLogger.info('Should not appear');
      expect(store.isEmpty, isTrue);
    });

    test('scope properties are merged into events', () async {
      final scope = logger.beginScope({'requestId': 'abc'});
      await scope.runAsync(() async {
        logger.info('Processing');
      });
      final event = store.events.first;
      expect(event.scopeProperties['requestId'], equals('abc'));
    });

    test('all convenience methods work', () {
      logger.trace('t');
      logger.debug('d');
      logger.info('i');
      logger.warning('w');
      logger.error('e');
      logger.fatal('f');
      expect(store.length, equals(6));
      expect(store.events[0].level, equals(PurpleLogLevel.trace));
      expect(store.events[1].level, equals(PurpleLogLevel.debug));
      expect(store.events[2].level, equals(PurpleLogLevel.info));
      expect(store.events[3].level, equals(PurpleLogLevel.warning));
      expect(store.events[4].level, equals(PurpleLogLevel.error));
      expect(store.events[5].level, equals(PurpleLogLevel.fatal));
    });
  });
}