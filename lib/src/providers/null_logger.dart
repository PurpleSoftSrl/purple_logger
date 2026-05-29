import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';

/// [LoggerProvider] that discards every log entry.
///
/// Useful as a no-op default for optional logger dependencies.
///
/// ```dart
/// LoggingBuilder().addProvider(NullLoggerProvider()).build();
/// ```
final class NullLoggerProvider extends LoggerProvider {
  /// Creates a [NullLogger] that discards all events.
  @override
  Logger createLogger(String category) => NullLogger();

  /// No external resources to release.
  @override
  void dispose() {}
}

/// A [Logger] that silently discards all log entries.
///
/// Use directly as a null-object default:
/// ```dart
/// class MyService {
///   MyService({Logger? logger}) : _logger = logger ?? NullLogger();
///   final Logger _logger;
/// }
/// ```
final class NullLogger with LoggerConvenience implements EventLogger {
  /// Empty category string.
  @override
  String get category => '';

  /// Always returns `false` — no log level is ever emitted.
  @override
  bool isEnabled(PurpleLogLevel level) => false;

  /// Discards the event.
  @override
  void write(LogEvent event) {
    // Discard.
  }

  /// No-op implementation that discards all arguments.
  @override
  void log(
    PurpleLogLevel level,
    Object? message, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Discard.
  }

  /// Creates a new [LoggingScope] with the given [properties].
  @override
  LoggingScope beginScope(Map<String, Object?> properties) =>
      LoggingScope(properties);
}
