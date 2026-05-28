import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';
import '../utils/timestamp_provider.dart';
import 'filter_rules.dart';

/// Internal [Logger] that dispatches [LogEvent]s to all registered providers.
///
/// Each provider gets its own filtered view via [FilterRuleSet].
/// A single [LogEvent] is allocated per [log] call and shared across providers.
final class LoggerImpl with LoggerConvenience implements Logger {
  final List<ProviderLogger> _providerLoggers;
  final FilterRuleSet _filters;
  final TimestampProvider _clock;

  LoggerImpl({
    required String category,
    required List<ProviderLogger> providerLoggers,
    required FilterRuleSet filters,
    required TimestampProvider clock,
  })  : _providerLoggers = providerLoggers,
        _filters = filters,
        _clock = clock,
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
    final event = LogEvent(
      level: level,
      category: _category,
      message: message?.toString() ?? '',
      timestamp: _clock.now(),
      properties: properties,
      scopeProperties: LoggingScope.currentProperties,
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