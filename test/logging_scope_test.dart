import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('LoggingScope', () {
    test('effectiveProperties returns own properties when no parent', () {
      final scope = LoggingScope({'requestId': 'abc'});
      expect(scope.effectiveProperties, equals({'requestId': 'abc'}));
    });

    test('child overrides parent properties', () {
      final parent = LoggingScope({'requestId': 'abc', 'userId': 1});
      final child = LoggingScope({'userId': 2}, parent);
      final effective = child.effectiveProperties;
      expect(effective['requestId'], equals('abc'));
      expect(effective['userId'], equals(2));
    });

    test('run propagates scope to Zone', () {
      final scope = LoggingScope({'requestId': 'abc-123'});
      scope.run(() {
        expect(LoggingScope.current, same(scope));
        expect(LoggingScope.currentProperties, containsPair('requestId', 'abc-123'));
      });
    });

    test('runAsync propagates scope to Zone', () async {
      final scope = LoggingScope({'requestId': 'abc-123'});
      await scope.runAsync(() async {
        expect(LoggingScope.current, same(scope));
        expect(LoggingScope.currentProperties, containsPair('requestId', 'abc-123'));
      });
    });

    test('scope is null outside run', () {
      expect(LoggingScope.current, isNull);
      expect(LoggingScope.currentProperties, isEmpty);
    });

    test('nested scopes merge correctly', () {
      final outer = LoggingScope({'a': 1, 'b': 2});
      outer.run(() {
        final inner = LoggingScope({'b': 3, 'c': 4});
        inner.run(() {
          final props = LoggingScope.currentProperties;
          expect(props, containsPair('a', 1));
          expect(props, containsPair('b', 3));
          expect(props, containsPair('c', 4));
        });
      });
    });
  });
}