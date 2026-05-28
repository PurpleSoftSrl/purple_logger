import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('FilterRule', () {
    test('specificity: provider+prefix > prefix only > provider only', () {
      expect(
        FilterRule(
                minimumLevel: PurpleLogLevel.error,
                providerType: ConsoleLoggerProvider,
                categoryPrefix: 'net')
            .specificity,
        equals(3),
      );
      expect(
        FilterRule(minimumLevel: PurpleLogLevel.error, categoryPrefix: 'net')
            .specificity,
        equals(1),
      );
      expect(
        FilterRule(
                minimumLevel: PurpleLogLevel.error,
                providerType: ConsoleLoggerProvider)
            .specificity,
        equals(2),
      );
    });

    test('matches provider type and category prefix', () {
      final rule = FilterRule(
        minimumLevel: PurpleLogLevel.error,
        providerType: ConsoleLoggerProvider,
        categoryPrefix: 'network',
      );
      expect(rule.matches(ConsoleLoggerProvider, 'network.http'), isTrue);
      expect(rule.matches(ConsoleLoggerProvider, 'other'), isFalse);
      expect(rule.matches(DebugLoggerProvider, 'network.http'), isFalse);
    });
  });

  group('FilterRuleSet', () {
    test('global minimum is the default', () {
      final rules = FilterRuleSet(globalMinimum: PurpleLogLevel.info);
      expect(
        rules.getEffectiveLevel(ConsoleLoggerProvider, 'Any'),
        equals(PurpleLogLevel.info),
      );
    });

    test('category prefix rule overrides global', () {
      final rules = FilterRuleSet(
        rules: [
          FilterRule(
              minimumLevel: PurpleLogLevel.error, categoryPrefix: 'network')
        ],
        globalMinimum: PurpleLogLevel.trace,
      );
      expect(
        rules.getEffectiveLevel(ConsoleLoggerProvider, 'network.http'),
        equals(PurpleLogLevel.error),
      );
      expect(
        rules.getEffectiveLevel(ConsoleLoggerProvider, 'other'),
        equals(PurpleLogLevel.trace),
      );
    });

    test('most specific rule wins', () {
      final rules = FilterRuleSet(
        rules: [
          FilterRule(
              minimumLevel: PurpleLogLevel.trace, categoryPrefix: 'network'),
          FilterRule(
              minimumLevel: PurpleLogLevel.fatal,
              providerType: ConsoleLoggerProvider,
              categoryPrefix: 'network'),
        ],
        globalMinimum: PurpleLogLevel.info,
      );
      // provider+prefix (specificity 3) wins over prefix only (specificity 1)
      expect(
        rules.getEffectiveLevel(ConsoleLoggerProvider, 'network.http'),
        equals(PurpleLogLevel.fatal),
      );
    });

    test('isEnabled respects filter', () {
      final rules = FilterRuleSet(globalMinimum: PurpleLogLevel.warning);
      expect(rules.isEnabled(ConsoleLoggerProvider, 'X', PurpleLogLevel.info),
          isFalse);
      expect(
          rules.isEnabled(ConsoleLoggerProvider, 'X', PurpleLogLevel.warning),
          isTrue);
      expect(rules.isEnabled(ConsoleLoggerProvider, 'X', PurpleLogLevel.none),
          isFalse);
    });
  });
}
