import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('HttpLogInterceptor', () {
    late MemoryLogStore store;
    late LoggerFactory factory;
    late Logger logger;
    late HttpLogInterceptor interceptor;

    setUp(() {
      store = MemoryLogStore();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      logger = factory.createLogger('Http');
      interceptor = HttpLogInterceptor(logger);
    });

    tearDown(() => factory.dispose());

    test('onRequest logs method and url', () {
      interceptor.onRequest('GET', 'https://api.example.com/orders');
      final event = store.events.first;
      expect(event.properties['http.method'], equals('GET'));
      expect(event.properties['http.url'], equals('https://api.example.com/orders'));
    });

    test('onResponse logs status and url', () {
      interceptor.onResponse(200, 'https://api.example.com/orders', durationMs: 42);
      final event = store.events.first;
      expect(event.properties['http.status'], equals(200));
      expect(event.properties['http.durationMs'], equals(42));
    });

    test('onError logs error with stackTrace', () {
      final err = Exception('timeout');
      interceptor.onError('GET', 'https://api.example.com', err, StackTrace.current);
      final event = store.events.first;
      expect(event.level, equals(PurpleLogLevel.error));
      expect(event.error, equals(err));
    });

    test('logHeaders includes headers when enabled', () {
      final verbose = HttpLogInterceptor(logger, logHeaders: true);
      verbose.onRequest('GET', 'https://x.com', headers: {'auth': 'token'});
      final event = store.events.first;
      expect(event.properties['http.request.headers'], isNotNull);
    });

    test('logHeaders omits headers when disabled', () {
      interceptor.onRequest('GET', 'https://x.com', headers: {'auth': 'token'});
      final event = store.events.first;
      expect(event.properties.containsKey('http.request.headers'), isFalse);
    });
  });
}