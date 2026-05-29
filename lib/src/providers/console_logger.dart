import 'dart:io' show stdout;

import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_formatter.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';
import '../formatting/simple_formatter.dart';

/// [LoggerProvider] that writes ANSI-colored output to [stdout].
///
/// Not available on web platforms.
///
/// ```dart
/// LoggingBuilder().addConsole();
/// LoggingBuilder().addConsole(formatter: const JsonFormatter());
/// ```
final class ConsoleLoggerProvider extends LoggerProvider {
  /// The [LogFormatter] used to render each event.
  final LogFormatter formatter;

  /// Creates a [ConsoleLoggerProvider] with an optional [formatter].
  ///
  /// Defaults to [SimpleFormatter] when not specified.
  ConsoleLoggerProvider({LogFormatter? formatter})
      : formatter = formatter ?? const SimpleFormatter();

  /// Creates a new [ConsoleLogger] for the given [category].
  @override
  Logger createLogger(String category) =>
      ConsoleLogger(category: category, formatter: formatter);

  /// No external resources to release.
  @override
  void dispose() {
    // No resources to release.
  }
}

/// [EventLogger] that writes formatted log events to [stdout] with ANSI colors.
///
/// Each event is formatted by a [LogFormatter] and colorized by severity.
final class ConsoleLogger with LoggerConvenience implements EventLogger {
  /// Logger category name.
  @override
  final String category;

  /// The [LogFormatter] used to render each event.
  final LogFormatter formatter;

  /// Creates a [ConsoleLogger] with the given [category] and [formatter].
  ConsoleLogger({required this.category, required this.formatter});

  /// Always enabled unless [PurpleLogLevel.none].
  @override
  bool isEnabled(PurpleLogLevel level) => !level.isNone;

  /// Formats and writes [event] to [stdout] with ANSI color.
  @override
  void write(LogEvent event) {
    final line = formatter.format(event);
    stdout.writeln(_colorize(event.level, line));
  }

  /// No-op — dispatching is handled by [LoggerImpl].
  @override
  void log(
    PurpleLogLevel level,
    Object? message, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Dispatched by LoggerImpl — not called directly.
  }

  /// Creates a new [LoggingScope] with the given [properties].
  @override
  LoggingScope beginScope(Map<String, Object?> properties) =>
      LoggingScope(properties);

  /// Applies ANSI color codes based on [level] severity.
  static String _colorize(PurpleLogLevel level, String text) {
    // Only colorize if stdout supports ANSI (most terminals do).
    final code = switch (level) {
      PurpleLogLevel.trace => '\x1B[37m', // white
      PurpleLogLevel.debug => '\x1B[36m', // cyan
      PurpleLogLevel.info => '\x1B[32m', // green
      PurpleLogLevel.warning => '\x1B[33m', // yellow
      PurpleLogLevel.error => '\x1B[31m', // red
      PurpleLogLevel.fatal => '\x1B[35m', // magenta
      PurpleLogLevel.none => '',
    };
    if (code.isEmpty) return text;
    return '$code$text\x1B[0m';
  }
}
