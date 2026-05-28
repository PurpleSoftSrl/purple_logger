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

final class LoggingBuilder {
  final List<LoggerProvider> _providers = [];
  PurpleLogLevel _minimumLevel = PurpleLogLevel.trace;
  final List<FilterRule> _rules = [];
  TimestampProvider _clock = TimestampProvider.utc;
  LoggerEnricher? _enricher;

  LoggingBuilder();

  LoggingBuilder addProvider(LoggerProvider provider) {
    _providers.add(provider);
    return this;
  }

  LoggingBuilder setMinimumLevel(PurpleLogLevel level) {
    _minimumLevel = level;
    return this;
  }

  LoggingBuilder addFilterRule(FilterRule rule) {
    _rules.add(rule);
    return this;
  }

  LoggingBuilder useTimestampProvider(TimestampProvider provider) {
    _clock = provider;
    return this;
  }

  LoggingBuilder enrichWith(Map<String, Object?> properties) {
    _enricher = _enricher != null
        ? _enricher!.merge(LoggerEnricher(properties))
        : LoggerEnricher(properties);
    return this;
  }

  LoggingBuilder enrichWithEnricher(LoggerEnricher enricher) {
    _enricher = _enricher != null ? _enricher!.merge(enricher) : enricher;
    return this;
  }

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

  factory LoggingBuilder.fromEnvironment({Map<String, String>? overrides}) {
    final config = EnvLoggingConfig.fromEnvironment(overrides: overrides);
    final builder = LoggingBuilder()
      ..setMinimumLevel(config.minimumLevel);

    final format = config.logFormat;
    final output = config.logOutput;

    if (output == 'file' || output == 'both') {
      final filePath = config.filePath ?? 'app.log';
      builder.addProvider(FileLoggerProvider(filePath: filePath,
        formatter: format == 'json' ? const JsonFormatter() : const SimpleFormatter(includeTimestamp: true)));
    }

    if (output == null || output == 'console' || output == 'both') {
      builder.addProvider(ConsoleLoggerProvider(
        formatter: format == 'json' ? const JsonFormatter() : const SimpleFormatter(includeTimestamp: true)));
    }

    builder.enrichWithEnricher(LoggerEnricher.fromEnvironment());

    return builder;
  }
}
