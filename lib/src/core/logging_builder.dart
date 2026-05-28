import '../abstractions/log_level.dart';
import '../abstractions/logger_factory.dart';
import '../abstractions/logger_provider.dart';
import '../utils/timestamp_provider.dart';
import 'filter_rules.dart';
import 'logger_factory_impl.dart';

/// Fluent builder for constructing a [LoggerFactory].
///
/// ```dart
/// final factory = LoggingBuilder()
///   .addConsole()
///   .setMinimumLevel(PurpleLogLevel.info)
///   .addFilterRule(FilterRule(
///     categoryPrefix: 'network',
///     minimumLevel: PurpleLogLevel.error,
///   ))
///   .build();
/// ```
final class LoggingBuilder {
  final List<LoggerProvider> _providers = [];
  PurpleLogLevel _minimumLevel = PurpleLogLevel.trace;
  final List<FilterRule> _rules = [];
  TimestampProvider _clock = TimestampProvider.utc;

  /// Registers a [LoggerProvider].
  LoggingBuilder addProvider(LoggerProvider provider) {
    _providers.add(provider);
    return this;
  }

  /// Sets the global minimum log level (catch-all).
  LoggingBuilder setMinimumLevel(PurpleLogLevel level) {
    _minimumLevel = level;
    return this;
  }

  /// Adds a filter rule for fine-grained level control.
  LoggingBuilder addFilterRule(FilterRule rule) {
    _rules.add(rule);
    return this;
  }

  /// Overrides the timestamp provider (useful for testing).
  LoggingBuilder useTimestampProvider(TimestampProvider provider) {
    _clock = provider;
    return this;
  }

  /// Builds the [LoggerFactory] with the configured providers and filters.
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
    );
  }
}