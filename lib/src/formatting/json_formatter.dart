import '../abstractions/log_event.dart';
import '../abstractions/log_formatter.dart';

/// JSON formatter — one JSON object per log event.
///
/// ```dart
/// LoggingBuilder().addConsole(formatter: const JsonFormatter());
/// ```
///
/// Output:
/// ```json
/// {"timestamp":"2026-05-28T14:23:01.123456Z","level":"info","category":"OrderService","message":"Order placed","properties":{"orderId":1042}}
/// ```
final class JsonFormatter implements LogFormatter {
  final bool prettyPrint;

  const JsonFormatter({this.prettyPrint = false});

  @override
  String format(LogEvent event) {
    final buf = StringBuffer('{');
    _field(buf, 'timestamp', event.timestamp.toIso8601String());
    _field(buf, 'level', event.level.name);
    _field(buf, 'category', event.category);
    _field(buf, 'message', event.message);
    if (event.properties.isNotEmpty) {
      buf.write(',"properties":');
      _writeMap(buf, event.properties);
    }
    if (event.scopeProperties.isNotEmpty) {
      buf.write(',"scopeProperties":');
      _writeMap(buf, event.scopeProperties);
    }
    if (event.error != null) {
      _field(buf, 'error', event.error.toString());
    }
    if (event.stackTrace != null) {
      _field(buf, 'stackTrace', event.stackTrace.toString());
    }
    buf.write('}');
    return buf.toString();
  }

  void _field(StringBuffer buf, String key, String value) {
    if (buf.length > 1) buf.write(',');
    buf.write('"$key":"${_escape(value)}"');
  }

  void _writeMap(StringBuffer buf, Map<String, Object?> map) {
    buf.write('{');
    var first = true;
    for (final e in map.entries) {
      if (!first) buf.write(',');
      first = false;
      buf.write('"${_escape(e.key)}":');
      _writeValue(buf, e.value);
    }
    buf.write('}');
  }

  void _writeValue(StringBuffer buf, Object? v) {
    if (v == null) {
      buf.write('null');
    } else if (v is String) {
      buf.write('"${_escape(v)}"');
    } else if (v is bool || v is num) {
      buf.write(v);
    } else {
      buf.write('"${_escape(v.toString())}"');
    }
  }

  String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');
}