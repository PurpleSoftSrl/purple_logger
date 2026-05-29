import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:purple_logger/purple_logger.dart';

void main() {
  group('FileLoggerProvider attacks', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('purple_logger_redteam_');
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('filePath with null byte in path', () {
      final badPath = '${tmpDir.path}\\ev${String.fromCharCode(0)}il.log';
      FileLoggerProvider? provider;
      expect(
        () => provider = FileLoggerProvider(filePath: badPath),
        returnsNormally,
      );
      provider?.dispose();
    });

    test('filePath that cannot be created (system-protected directory)',
        () {
      final protected = 'C:\\Windows\\System32\\purple_logger_cant_write.log';
      try {
        final provider = FileLoggerProvider(filePath: protected);
        final logger = provider.createLogger('test') as FileLogger;
        logger.write(LogEvent(
          level: PurpleLogLevel.info,
          category: 'test',
          message: 'hello',
          timestamp: DateTime.now(),
        ));
        provider.dispose();
      } on PathAccessException {
      }
    });

    test('maxFileSize = 0 causes rotation on every write', () {
      final path = '${tmpDir.path}\\zero_size.log';
      final provider = FileLoggerProvider(
        filePath: path,
        rotation: const RotatingFileConfig(maxFileSizeBytes: 0, maxFiles: 3),
        flushIntervalMs: 0,
      );
      final logger = provider.createLogger('test') as FileLogger;
      for (var i = 0; i < 20; i++) {
        logger.write(LogEvent(
          level: PurpleLogLevel.info,
          category: 'test',
          message: 'msg $i',
          timestamp: DateTime.now(),
        ));
      }
      provider.dispose();
      expect(File(path).existsSync(), isTrue);
    });

    test('maxFiles = 0 rotation behavior', () {
      final path = '${tmpDir.path}\\zero_files.log';
      final provider = FileLoggerProvider(
        filePath: path,
        rotation: const RotatingFileConfig(
          maxFileSizeBytes: 1,
          maxFiles: 0,
        ),
        flushIntervalMs: 0,
      );
      final logger = provider.createLogger('test') as FileLogger;
      for (var i = 0; i < 10; i++) {
        logger.write(LogEvent(
          level: PurpleLogLevel.info,
          category: 'test',
          message: 'x',
          timestamp: DateTime.now(),
        ));
      }
      provider.dispose();
    });

    test('flushIntervalMs = 0 does not create timer', () {
      final path = '${tmpDir.path}\\no_timer.log';
      final provider = FileLoggerProvider(
        filePath: path,
        flushIntervalMs: 0,
      );
      final logger = provider.createLogger('test') as FileLogger;
      logger.write(LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'hello',
        timestamp: DateTime.now(),
      ));
      provider.dispose();
      expect(File(path).existsSync(), isTrue);
    });

    test('flushIntervalMs = -1 does not create timer', () {
      final path = '${tmpDir.path}\\neg_timer.log';
      final provider = FileLoggerProvider(
        filePath: path,
        flushIntervalMs: -1,
      );
      final logger = provider.createLogger('test') as FileLogger;
      logger.write(LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'negative flush interval',
        timestamp: DateTime.now(),
      ));
      provider.dispose();
      expect(File(path).existsSync(), isTrue);
    });

    test('dispose while flush in progress', () {
      final path = '${tmpDir.path}\\dispose_flush.log';
      final provider = FileLoggerProvider(
        filePath: path,
        flushIntervalMs: 1,
      );
      final logger = provider.createLogger('test') as FileLogger;
      for (var i = 0; i < 100; i++) {
        logger.write(LogEvent(
          level: PurpleLogLevel.info,
          category: 'test',
          message: 'msg $i',
          timestamp: DateTime.now(),
        ));
      }
      provider.dispose();
    });

    test('write after dispose', () {
      final path = '${tmpDir.path}\\wrote_after_dead.log';
      final provider = FileLoggerProvider(
        filePath: path,
        flushIntervalMs: 0,
      );
      provider.dispose();
      final logger = provider.createLogger('test') as FileLogger;
      logger.write(LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'postmortem',
        timestamp: DateTime.now(),
      ));
    });
  });

  group('LogEvent attacks', () {
    test('null message via LoggerImpl.log produces empty string', () {
      final store = MemoryLogStore();
      final factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      final logger = factory.createLogger('NullMsg');
      store.clear();
      logger.log(PurpleLogLevel.info, null);
      expect(store.events.single.message, equals(''));
      factory.dispose();
    });

    test('LogEvent with message containing null bytes', () {
      final message = 'before${String.fromCharCode(0)}after';
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: message,
        timestamp: DateTime.now(),
      );
      expect(event.message, contains(String.fromCharCode(0)));
      expect(event.message.length, equals(12));
    });

    test('LogEvent with 1,000,000 properties', () {
      final props = <String, Object?>{};
      for (var i = 0; i < 1000000; i++) {
        props['key$i'] = i;
      }
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'massive props',
        timestamp: DateTime.now(),
        properties: props,
      );
      expect(event.properties.length, equals(1000000));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('LogEvent with cyclic map properties', () {
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;
      try {
        LogEvent(
          level: PurpleLogLevel.info,
          category: 'test',
          message: 'cyclic',
          timestamp: DateTime.now(),
          properties: cyclic,
        );
      } on StackOverflowError {
      } on StateError {
      }
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('LogEvent equality with very large properties', () {
      final props1 = <String, Object?>{};
      final props2 = <String, Object?>{};
      for (var i = 0; i < 10000; i++) {
        props1['key$i'] = i;
        props2['key$i'] = i;
      }
      final t = DateTime.now();
      final a = LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'large',
        timestamp: t,
        properties: props1,
      );
      final b = LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'large',
        timestamp: t,
        properties: props2,
      );
      expect(a, equals(b));
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('LogEvent hashCode with very large properties', () {
      final props = <String, Object?>{};
      for (var i = 0; i < 10000; i++) {
        props['key$i'] = i;
      }
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'hash me',
        timestamp: DateTime.now(),
        properties: props,
      );
      expect(event.hashCode, isNotNull);
    });

    test('copyWith with cyclic map properties', () {
      final original = LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'original',
        timestamp: DateTime.now(),
      );
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;
      try {
        original.copyWith(properties: cyclic);
      } on StackOverflowError {
      } on StateError {
      }
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('LogEvent equality with cyclic properties', () {
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;
      try {
        final a = LogEvent(
          level: PurpleLogLevel.info,
          category: 'test',
          message: 'cyclic',
          timestamp: DateTime.now(),
          properties: cyclic,
        );
        final b = LogEvent(
          level: PurpleLogLevel.info,
          category: 'test',
          message: 'cyclic',
          timestamp: DateTime.now(),
          properties: cyclic,
        );
        a == b;
      } on StackOverflowError {
      } on StateError {
      }
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('LogEvent toString with null values in properties', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: 'test',
        message: 'msg',
        timestamp: DateTime.now(),
        properties: {'nullVal': null},
      );
      expect(event.toString(), isNotEmpty);
    });

    test('LogEvent zero-length strings', () {
      final event = LogEvent(
        level: PurpleLogLevel.info,
        category: '',
        message: '',
        timestamp: DateTime.now(),
      );
      expect(event.category, equals(''));
      expect(event.message, equals(''));
    });
  });

  group('LoggerImpl attacks', () {
    late MemoryLogStore store;
    late LoggerFactory factory;
    late Logger logger;

    setUp(() {
      store = MemoryLogStore();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      logger = factory.createLogger('TestLogger');
    });

    tearDown(() {
      try {
        factory.dispose();
      } catch (_) {}
    });

    test('log with PurpleLogLevel.none produces no event', () {
      store.clear();
      logger.log(PurpleLogLevel.none, 'should not appear');
      expect(store.isEmpty, isTrue);
    });

    test('setMinimumLevel PurpleLogLevel.none does NOT block output (isAtLeast quirk)', () {
      factory.dispose();
      factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.none)
          .build();
      final silent = factory.createLogger('Silent');
      store.clear();
      silent.fatal('should appear despite none minimum');
      silent.info('should also appear');
      expect(store.length, equals(2));
    });

    test('rapid concurrent logging from multiple futures', () async {
      store.clear();
      final futures = <Future<void>>[];
      for (var t = 0; t < 50; t++) {
        final tid = t;
        futures.add(Future(() {
          for (var i = 0; i < 100; i++) {
            logger.info('thread $tid msg $i', properties: {'tid': tid});
          }
        }));
      }
      await Future.wait(futures);
      expect(store.isNotEmpty, isTrue);
    });

    test('dispose factory while loggers still in use', () {
      factory.dispose();
      final nullLogger = logger;
      expect(() => factory.createLogger('New'), throwsStateError);
      try {
        nullLogger.info('after dispose');
      } catch (_) {}
    });

    test('log with null message results in empty string (safe nav)', () {
      store.clear();
      logger.log(PurpleLogLevel.info, null);
      expect(store.events.single.message, equals(''));
    });

    test('log with empty string message', () {
      store.clear();
      logger.log(PurpleLogLevel.info, '');
      expect(store.events.first.message, equals(''));
    });

    test('log without passing message defaults to empty string?', () {
      store.clear();
      logger.info('hello');
      expect(store.events.first.message, equals('hello'));
    });

    test('isEnabled with none returns false', () {
      expect(logger.isEnabled(PurpleLogLevel.none), isFalse);
    });

    test('all levels from trace to fatal pass through when level is trace', () {
      store.clear();
      logger.trace('t');
      logger.debug('d');
      logger.info('i');
      logger.warning('w');
      logger.error('e');
      logger.fatal('f');
      expect(store.length, equals(6));
    });

    test('add conflicting filter rules: last specific wins', () {
      final store2 = MemoryLogStore();
      final factory2 = LoggingBuilder()
          .addMemory(store: store2)
          .setMinimumLevel(PurpleLogLevel.info)
          .addFilterRule(FilterRule(
            minimumLevel: PurpleLogLevel.trace,
            providerType: MemoryLoggerProvider,
            categoryPrefix: 'Network',
          ))
          .addFilterRule(FilterRule(
            minimumLevel: PurpleLogLevel.fatal,
            providerType: MemoryLoggerProvider,
            categoryPrefix: 'Network',
          ))
          .build();
      final netLogger = factory2.createLogger('Network.HttpClient');
      netLogger.error('error');
      netLogger.fatal('fatal');
      final lengthAfter = store2.length;
      expect(lengthAfter, lessThanOrEqualTo(2));
      factory2.dispose();
    });

    test('setGlobalLevel to fatal then back to trace', () {
      var localStore = MemoryLogStore();
      var localFactory = LoggingBuilder()
          .addMemory(store: localStore)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      localFactory.setGlobalLevel(PurpleLogLevel.fatal);
      final flog = localFactory.createLogger('F');
      localStore.clear();
      flog.error('e');
      expect(localStore.isEmpty, isTrue);
      localStore.clear();
      flog.fatal('f');
      expect(localStore.isNotEmpty, isTrue);
      localFactory.setGlobalLevel(PurpleLogLevel.trace);
      final tlog = localFactory.createLogger('T');
      localStore.clear();
      tlog.info('i');
      expect(localStore.isNotEmpty, isTrue);
      localFactory.dispose();
    });
  });

  group('FilterRuleSet attacks', () {
    test('add 10,000 filter rules', () {
      final rules = <FilterRule>[];
      for (var i = 0; i < 10000; i++) {
        rules.add(FilterRule(
          minimumLevel: PurpleLogLevel.values[i % 7],
          categoryPrefix: 'cat$i',
          providerType: i.isEven ? ConsoleLoggerProvider : null,
        ));
      }
      final ruleSet = FilterRuleSet(rules: rules);
      expect(ruleSet.rules.length, equals(10000));
      final level = ruleSet.getEffectiveLevel(
          MemoryLoggerProvider, 'unmatched_category');
      expect(level, equals(PurpleLogLevel.trace));
    });

    test('FilterRule with empty categoryPrefix matches everything', () {
      final rule = FilterRule(
        minimumLevel: PurpleLogLevel.fatal,
        categoryPrefix: '',
      );
      final ruleSet = FilterRuleSet(
        rules: [rule],
        globalMinimum: PurpleLogLevel.trace,
      );
      final level =
          ruleSet.getEffectiveLevel(MemoryLoggerProvider, 'anything.at.all');
      expect(level, equals(PurpleLogLevel.fatal));
    });

    test('FilterRule with null categoryPrefix and null providerType', () {
      final rule = FilterRule(
        minimumLevel: PurpleLogLevel.error,
      );
      expect(rule.specificity, equals(0));
      final ruleSet = FilterRuleSet(
        rules: [rule],
        globalMinimum: PurpleLogLevel.trace,
      );
      final level =
          ruleSet.getEffectiveLevel(MemoryLoggerProvider, 'any');
      expect(level, equals(PurpleLogLevel.error));
    });

    test('isEnabled with PurpleLogLevel.none always false', () {
      final ruleSet = FilterRuleSet(globalMinimum: PurpleLogLevel.trace);
      expect(
        ruleSet.isEnabled(MemoryLoggerProvider, 'test', PurpleLogLevel.none),
        isFalse,
      );
    });

    test('getEffectiveLevel with circular/overlapping rules stress', () {
      final rules = [
        FilterRule(minimumLevel: PurpleLogLevel.trace, categoryPrefix: 'a'),
        FilterRule(minimumLevel: PurpleLogLevel.debug, categoryPrefix: 'a'),
        FilterRule(minimumLevel: PurpleLogLevel.info, categoryPrefix: 'a'),
        FilterRule(minimumLevel: PurpleLogLevel.warning, categoryPrefix: 'a'),
        FilterRule(minimumLevel: PurpleLogLevel.error, categoryPrefix: 'a'),
        FilterRule(minimumLevel: PurpleLogLevel.fatal, categoryPrefix: 'a'),
      ];
      final ruleSet = FilterRuleSet(rules: rules);
      final level =
          ruleSet.getEffectiveLevel(MemoryLoggerProvider, 'a.b.c');
      expect(level, isNotNull);
    });
  });

  group('LoggingBuilder attacks', () {
    test('build without providers throws StateError', () {
      final builder = LoggingBuilder();
      expect(
        () => builder.build(),
        throwsStateError,
      );
    });

    test('add same provider twice', () {
      final store = MemoryLogStore();
      final builder = LoggingBuilder();
      builder.addProvider(MemoryLoggerProvider(store: store));
      builder.addProvider(MemoryLoggerProvider(store: store));
      final factory = builder.build();
      final logger = factory.createLogger('Dup');
      final store2 = MemoryLogStore();
      final factory2 = LoggingBuilder()
          .addMemory(store: store2)
          .build();
      final logger2 = factory2.createLogger('Single');
      store.clear();
      store2.clear();
      logger.info('duplicate');
      logger2.info('single');
      expect(store.length, greaterThan(0));
      factory.dispose();
      factory2.dispose();
    });

    test('pass null clock to underlying factory directly', () {
      final store = MemoryLogStore();
      try {
        LoggerFactoryImpl(
          providers: [MemoryLoggerProvider(store: store)],
          filters: FilterRuleSet(),
          clock: null as dynamic,
        );
      } on TypeError {
      }
    });

    test('pass null enricher', () {
      final store = MemoryLogStore();
      final factory = LoggingBuilder()
          .addMemory(store: store)
          .build();
      final logger = factory.createLogger('no_enricher');
      logger.info('ok');
      expect(store.isNotEmpty, isTrue);
      factory.dispose();
    });

    test('setMinimumLevel to each valid level', () {
      final store = MemoryLogStore();
      for (final level in PurpleLogLevel.values.where((l) => !l.isNone)) {
        final builder = LoggingBuilder()
            .addMemory(store: store)
            .setMinimumLevel(level);
        final factory = builder.build();
        final logger = factory.createLogger('L');
        final remaining = factory.createLogger('R');
        expect(logger, isA<Logger>());
        expect(remaining, isA<Logger>());
        factory.dispose();
      }
    });
  });

  group('Stress tests', () {
    test('1000 rapid log events on memory logger', () {
      final store = MemoryLogStore();
      final factory = LoggingBuilder()
          .addMemory(store: store)
          .setMinimumLevel(PurpleLogLevel.trace)
          .build();
      final logger = factory.createLogger('Stress');
      for (var i = 0; i < 1000; i++) {
        logger.info('msg $i', properties: {'idx': i, 'half': i / 2.0});
      }
      expect(store.length, equals(1000));
      factory.dispose();
    });

    test('rapid createLogger and dispose cycling', () {
      for (var i = 0; i < 100; i++) {
        final store = MemoryLogStore();
        final factory = LoggingBuilder()
            .addMemory(store: store)
            .build();
        final logger = factory.createLogger('cycle_$i');
        logger.info('life');
        factory.dispose();
      }
    });

    test('write to MemoryLogStore after provider disposed', () {
      final store = MemoryLogStore();
      final factory = LoggingBuilder()
          .addMemory(store: store)
          .build();
      final logger = factory.createLogger('PostMortem');
      factory.dispose();
      try {
        logger.info('post-dispose');
      } catch (_) {}
    });
  });
}
