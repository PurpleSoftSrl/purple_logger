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
  @override
  Logger createLogger(String category) => NullLogger();

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
  @override
  String get category => '';

  @override
  bool isEnabled(PurpleLogLevel level) => false;

  @override
  void write(LogEvent event) {
    // Discard.
  }

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

  @override
  LoggingScope beginScope(Map<String, Object?> properties) =>
      LoggingScope(properties);
}