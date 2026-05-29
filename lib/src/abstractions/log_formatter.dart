import 'log_event.dart';

/// Formats a [LogEvent] into a string representation.
///
/// Implement this to produce custom output formats (syslog, logfmt, etc.).
///
/// ```dart
/// final class LogfmtFormatter implements LogFormatter {
///   @override
///   String format(LogEvent event) {
///     final buf = StringBuffer()
///       ..write('level=${event.level.name} ')
///       ..write('msg="${event.message}"');
///     for (final e in event.properties.entries) {
///       buf.write(' ${e.key}=${e.value}');
///     }
///     return buf.toString();
///   }
/// }
/// ```
abstract interface class LogFormatter {
  /// Formats [event] into a single output line.
  String format(LogEvent event);
}
