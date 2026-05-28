import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';
import '../utils/timestamp_provider.dart';
import 'filter_rules.dart';
import 'logger_enricher.dart';

final class LoggerImpl with LoggerConvenience implements Logger {
  final List<ProviderLogger> _providerLoggers;
  final FilterRuleSet _filters;
  final TimestampProvider _clock;
  final LoggerEnricher? _enricher;

  LoggerImpl({
    required String category,
    required List<ProviderLogger> providerLoggers,
    required FilterRuleSet filters,
    required TimestampProvider clock,
    LoggerEnricher? enricher,
  })  : _providerLoggers = providerLoggers,
        _filters = filters,
        _clock = clock,
        _enricher = enricher,
        _category = category;

  final String _category;

  @override
  String get category => _category;

  @override
  bool isEnabled(PurpleLogLevel level) {
    if (level.isNone) return false;
    for (final pl in _providerLoggers) {
      if (_filters.isEnabled(pl.providerType, _category, level)) {
        return true;
      }
    }
    return false;
  }

  @override
  void log(
    PurpleLogLevel level,
    Object? message, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.isNone) return;

    // Zero-alloc fast path: if no provider is enabled, skip entirely.
    bool anyEnabled = false;
    for (final pl in _providerLoggers) {
      if (_filters.isEnabled(pl.providerType, _category, level)) {
        anyEnabled = true;
        break;
      }
    }
    if (!anyEnabled) return;

    // Single LogEvent allocation, shared across all providers.
    final scopeProps = Map<String, Object?>.from(LoggingScope.currentProperties);
    if (_enricher != null) {
      scopeProps.addAll(_enricher.properties);
    }

    final event = LogEvent(
      level: level,
      category: _category,
      message: message?.toString() ?? '',
      timestamp: _clock.now(),
      properties: properties,
      scopeProperties: scopeProps,
      error: error,
      stackTrace: stackTrace,
    );

    for (final pl in _providerLoggers) {
      if (_filters.isEnabled(pl.providerType, _category, level)) {
        pl.write(event);
      }
    }
  }

  @override
  LoggingScope beginScope(Map<String, Object?> properties) =>
      LoggingScope(properties);
}

/// A logger wrapper that pairs a [LoggerProvider]-created logger with its
/// provider type for filter rule matching.
///
/// If the underlying logger implements [EventLogger], events are dispatched
/// via [EventLogger.write]; otherwise the event is silently consumed.
final class ProviderLogger {
  final Logger _logger;
  final Type providerType;

  ProviderLogger(this._logger, this.providerType);

  /// Dispatches [event] to the underlying logger.
  void write(LogEvent event) {
    final el = _logger;
    if (el is EventLogger) {
      el.write(event);
    }
  }
}