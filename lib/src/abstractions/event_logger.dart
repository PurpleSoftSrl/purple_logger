import 'log_event.dart';
import 'logger.dart';

/// A [Logger] that receives fully assembled [LogEvent] instances.
///
/// Implement this instead of [Logger] when you need access to the complete
/// event (including scope-merged properties) and want to avoid double
/// allocation — the [LogEvent] is already built by the pipeline.
///
/// ```dart
/// final class SyslogLogger implements EventLogger {
///   @override
///   final String category = 'Syslog';
///
///   @override
///   void write(LogEvent event) => syslog(event.level.label, event.message);
/// }
/// ```
abstract interface class EventLogger implements Logger {
  /// Called with the fully assembled [LogEvent].
  void write(LogEvent event);
}
