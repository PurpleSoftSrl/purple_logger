import '../abstractions/log_level.dart';
import '../abstractions/logger_factory.dart';
import '../abstractions/logger_provider.dart';
import '../formatting/json_formatter.dart';
import '../formatting/simple_formatter.dart';
import '../providers/console_logger.dart';
import '../providers/file_logger.dart';
import '../utils/timestamp_provider.dart';
import 'env_logging_config.dart';
import 'filter_rules.dart';
import 'logger_enricher.dart';
import 'logger_factory_impl.dart';

/// Builder that configures and creates a [LoggerFactory] instance.
///
/// Supports chained configuration of providers, filters, enrichment,
/// and timestamp providers. At least one [LoggerProvider] must be
/// registered via [addProvider] before calling [build].
///
/// ```dart
/// final factory = LoggingBuilder()
///   .addConsole()
///   .addMemory(store: myStore)
///   .setMinimumLevel(PurpleLogLevel.info)
///   .addFilterRule(FilterRule(
///     minimumLevel: PurpleLogLevel.debug,
///     categoryPrefix: 'MyService',
///   ))
///   .build();
/// ```
///
/// Use [LoggingBuilder.fromEnvironment] to configure from environment
/// variables (`PLOG_LEVEL`, `PLOG_FORMAT`, `PLOG_OUTPUT`, `PLOG_FILE_PATH`).
final class LoggingBuilder {
  final List<LoggerProvider> _providers = [];
  PurpleLogLevel _minimumLevel = PurpleLogLevel.trace;
  final List<FilterRule> _rules = [];
  TimestampProvider _clock = TimestampProvider.utc;
  LoggerEnricher? _enricher;

  LoggingBuilder();

  /// Registers a [LoggerProvider] to receive log events.
  ///
  /// Multiple providers can be registered; each receives every log event
  /// that passes filtering.
  LoggingBuilder addProvider(LoggerProvider provider) {
    _providers.add(provider);
    return this;
  }

  /// Sets the global minimum [PurpleLogLevel].
  ///
  /// Events below this level are discarded before reaching any provider.
  /// Override per-category or per-provider with [addFilterRule].
  LoggingBuilder setMinimumLevel(PurpleLogLevel level) {
    _minimumLevel = level;
    return this;
  }

  /// Adds a [FilterRule] for fine-grained level control.
  LoggingBuilder addFilterRule(FilterRule rule) {
    _rules.add(rule);
    return this;
  }

  /// Sets the [TimestampProvider] used for all log event timestamps.
  ///
  /// Defaults to [TimestampProvider.utc].
  LoggingBuilder useTimestampProvider(TimestampProvider provider) {
    _clock = provider;
    return this;
  }

  /// Adds static [properties] that are merged into every log event.
  ///
  /// Multiple calls are cumulative.
  LoggingBuilder enrichWith(Map<String, Object?> properties) {
    _enricher = _enricher != null
        ? _enricher!.merge(LoggerEnricher(properties))
        : LoggerEnricher(properties);
    return this;
  }

  /// Registers a [LoggerEnricher] whose properties are merged into every
  /// log event.
  ///
  /// Multiple calls are cumulative; later properties override earlier ones
  /// with the same key.
  LoggingBuilder enrichWithEnricher(LoggerEnricher enricher) {
    _enricher = _enricher != null ? _enricher!.merge(enricher) : enricher;
    return this;
  }

  /// Builds and returns a [LoggerFactory] with the current configuration.
  ///
  /// Throws [StateError] if no providers have been registered.
  LoggerFactory build() {
    if (_providers.isEmpty) {
      throw StateError(
        'At least one LoggerProvider must be registered via addProvider()',
      );
    }
    return LoggerFactoryImpl(
      providers: List.of(_providers),
      filters: FilterRuleSet(
        rules: List.of(_rules),
        globalMinimum: _minimumLevel,
      ),
      clock: _clock,
      enricher: _enricher,
    );
  }

  /// Creates a [LoggingBuilder] pre-configured from environment variables.
  ///
  /// Reads `PLOG_LEVEL`, `PLOG_FORMAT`, `PLOG_OUTPUT`, and `PLOG_FILE_PATH`.
  /// [overrides] can be used to supply values in tests.
  factory LoggingBuilder.fromEnvironment({Map<String, String>? overrides}) {
    final config = EnvLoggingConfig.fromEnvironment(overrides: overrides);
    final builder = LoggingBuilder()..setMinimumLevel(config.minimumLevel);

    final format = config.logFormat;
    final output = config.logOutput;

    if (output == 'file' || output == 'both') {
      final filePath = config.filePath ?? 'app.log';
      builder.addProvider(FileLoggerProvider(
          filePath: filePath,
          formatter: format == 'json'
              ? const JsonFormatter()
              : const SimpleFormatter(includeTimestamp: true)));
    }

    if (output == null || output == 'console' || output == 'both') {
      builder.addProvider(ConsoleLoggerProvider(
          formatter: format == 'json'
              ? const JsonFormatter()
              : const SimpleFormatter(includeTimestamp: true)));
    }

    builder.enrichWithEnricher(LoggerEnricher.fromEnvironment());

    return builder;
  }
}
