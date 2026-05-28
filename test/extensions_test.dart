import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('LoggerTagExtension', () {
    late MemoryLogStore store;
    late LoggerFactory factory;
    late Logger logger;

    setUp(() {
      store = MemoryLogStore();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      logger = factory.createLogger('Svc');
    });

    tearDown(() => factory.dispose());

    test('infoTagged adds tag to properties', () {
      logger.infoTagged('auth', 'User signed in', properties: {'userId': 42});
      final event = store.events.first;
      expect(event.properties['tag'], equals('auth'));
      expect(event.properties['userId'], equals(42));
    });

    test('errorTagged includes tag, error, and stackTrace', () {
      final err = Exception('fail');
      logger.errorTagged('payment', 'Charge failed',
          error: err, stackTrace: StackTrace.current);
      final event = store.events.first;
      expect(event.properties['tag'], equals('payment'));
      expect(event.error, equals(err));
    });
  });

  group('LoggerExceptionExtension', () {
    late MemoryLogStore store;
    late LoggerFactory factory;
    late Logger logger;

    setUp(() {
      store = MemoryLogStore();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      logger = factory.createLogger('Svc');
    });

    tearDown(() => factory.dispose());

    test('logException adds errorType and errorMessage', () {
      final err = FormatException('bad input');
      logger.logException(err, StackTrace.current);
      final event = store.events.first;
      expect(event.properties['errorType'], equals('FormatException'));
      expect(event.properties['errorMessage'], equals('FormatException: bad input'));
    });

    test('logException with custom message', () {
      final err = FormatException('bad');
      logger.logException(err, StackTrace.current, message: 'Validation failed');
      final event = store.events.first;
      expect(event.message, equals('Validation failed'));
    });

    test('logException with custom properties', () {
      final err = Exception('x');
      logger.logException(err, StackTrace.current, properties: {'orderId': 42});
      final event = store.events.first;
      expect(event.properties['orderId'], equals(42));
      expect(event.properties['errorType'], isNotNull);
    });

    test('logException at custom level', () {
      final err = Exception('x');
      logger.logException(err, StackTrace.current, level: PurpleLogLevel.fatal);
      final event = store.events.first;
      expect(event.level, equals(PurpleLogLevel.fatal));
    });
  });
}