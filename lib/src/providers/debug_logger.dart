import 'dart:developer' as developer;

import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';

/// [LoggerProvider] that writes to `dart:developer.log()`.
///
/// Visible in Flutter DevTools and Dart DevTools. Works on all platforms
/// including web.
///
/// ```dart
/// LoggingBuilder().addDebug();
/// ```
final class DebugLoggerProvider extends LoggerProvider {
  @override
  Logger createLogger(String category) => DebugLogger(category: category);

  @override
  void dispose() {}
}

/// [EventLogger] that writes to `dart:developer.log()`.
final class DebugLogger with LoggerConvenience implements EventLogger {
  @override
  final String category;

  DebugLogger({required this.category});

  @override
  bool isEnabled(PurpleLogLevel level) => !level.isNone;

  @override
  void write(LogEvent event) {
    developer.log(
      event.message,
      time: event.timestamp,
      level: _mapLevel(event.level),
      name: event.category,
      error: event.error,
      stackTrace: event.stackTrace,
    );
  }

  @override
  void log(
    PurpleLogLevel level,
    Object? message, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  LoggingScope beginScope(Map<String, Object?> properties) =>
      LoggingScope(properties);

  /// Maps [PurpleLogLevel] to `dart:developer` log levels.
  static int _mapLevel(PurpleLogLevel level) => switch (level) {
        PurpleLogLevel.trace => 500,
        PurpleLogLevel.debug => 800,
        PurpleLogLevel.info => 900,
        PurpleLogLevel.warning => 1000,
        PurpleLogLevel.error => 1200,
        PurpleLogLevel.fatal => 1500,
        PurpleLogLevel.none => 0,
      };
}
