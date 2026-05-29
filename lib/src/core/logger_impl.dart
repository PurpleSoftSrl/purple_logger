import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';
import '../utils/timestamp_provider.dart';
import 'filter_rules.dart';
import 'logger_enricher.dart';

/// Default [Logger] implementation that routes events through provider loggers
/// with filter, scope, and enrichment support.
///
/// A single [LogEvent] is allocated per [log] call and shared across all
/// enabled providers — zero redundant allocations.
final class LoggerImpl with LoggerConvenience implements Logger {
  final List<ProviderLogger> _providerLoggers;
  final FilterRuleSet _filters;
  final TimestampProvider _clock;
  final LoggerEnricher? _enricher;

  /// Creates a [LoggerImpl].
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

  /// The logger category name.
  @override
  String get category => _category;

  /// Returns `true` if at least one provider would emit [level].
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

  /// Assembles a [LogEvent] and dispatches it to all enabled providers.
  ///
  /// Scope properties and enricher properties are merged into the event
  /// automatically. [PurpleLogLevel.none] is silently discarded.
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
    final scopeProps =
        Map<String, Object?>.from(LoggingScope.currentProperties);
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

  /// Creates a new [LoggingScope] with the given [properties].
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

  /// The runtime type of the [LoggerProvider] that created [_logger].
  final Type providerType;

  /// Creates a [ProviderLogger] wrapping [_logger] with [providerType].
  ProviderLogger(this._logger, this.providerType);

  /// Dispatches [event] to the underlying logger.
  ///
  /// If [_logger] implements [EventLogger], calls [EventLogger.write].
  /// Otherwise the event is silently consumed.
  void write(LogEvent event) {
    final el = _logger;
    if (el is EventLogger) {
      el.write(event);
    }
  }
}
