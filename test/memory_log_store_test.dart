import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('MemoryLogStore', () {
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

    test('eventsAtOrAbove filters by level', () {
      logger.info('info');
      logger.warning('warn');
      logger.error('error');
      expect(store.eventsAtOrAbove(PurpleLogLevel.warning), hasLength(2));
    });

    test('eventsForCategory filters by category', () {
      factory.createLogger('A').info('from A');
      factory.createLogger('B').info('from B');
      expect(store.eventsForCategory('A'), hasLength(1));
    });

    test('eventsForTag filters by tag', () {
      logger.infoTagged('auth', 'Login');
      logger.info('Untagged');
      expect(store.eventsForTag('auth'), hasLength(1));
    });

    test('exportAsJson produces valid JSON', () {
      logger.info('Hello', properties: {'key': 42});
      final json = store.exportAsJson();
      expect(json, startsWith('[{'));
      expect(json, contains('"level":"info"'));
      expect(json, contains('"key":42'));
    });

    test('exportAsJson returns empty array when no events', () {
      expect(store.exportAsJson(), equals('[]'));
    });

    test('clear removes all events', () {
      logger.info('a');
      logger.info('b');
      expect(store.length, equals(2));
      store.clear();
      expect(store.isEmpty, isTrue);
    });

    test('maxCapacity evicts oldest', () {
      final bounded = MemoryLogStore(maxCapacity: 2);
      final f = LoggingBuilder()
          .addMemory(store: bounded)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      final l = f.createLogger('T');
      l.info('1');
      l.info('2');
      l.info('3');
      expect(bounded.length, equals(2));
      expect(bounded.events.first.message, equals('2'));
      expect(bounded.events.last.message, equals('3'));
      f.dispose();
    });
  });
}