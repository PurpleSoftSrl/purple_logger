import '../abstractions/log_event.dart';
import '../abstractions/log_formatter.dart';

/// Human-readable single-line formatter (default for [ConsoleLoggerProvider]).
///
/// Format: `2026-05-28T14:23:01.123456Z [INFO ] Category » Message {props} scope:{scopeProps}`
///
/// Disable the timestamp for cleaner test output:
/// ```dart
/// LoggingBuilder().addConsole(formatter: const SimpleFormatter(includeTimestamp: false));
/// ```
final class SimpleFormatter implements LogFormatter {
  final bool includeTimestamp;

  const SimpleFormatter({this.includeTimestamp = true});

  @override
  String format(LogEvent event) {
    final buf = StringBuffer();
    if (includeTimestamp) {
      buf.write('${event.timestamp.toIso8601String()} ');
    }
    buf.write('[${event.level.label.padRight(4)}] ');
    buf.write('${event.category} » ');
    buf.write(event.message);

    if (event.properties.isNotEmpty) {
      buf.write(' ');
      _writeMap(buf, event.properties);
    }
    if (event.scopeProperties.isNotEmpty) {
      buf.write(' scope:');
      _writeMap(buf, event.scopeProperties);
    }
    if (event.error != null) {
      buf.write('\n  Error: ${event.error}');
      if (event.stackTrace != null) {
        buf.write('\n  StackTrace: ${event.stackTrace}');
      }
    }
    return buf.toString();
  }

  void _writeMap(StringBuffer buf, Map<String, Object?> map) {
    buf.write('{');
    var first = true;
    for (final e in map.entries) {
      if (!first) buf.write(', ');
      first = false;
      buf.write('${e.key}: ${e.value}');
    }
    buf.write('}');
  }
}