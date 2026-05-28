import 'logger.dart';

/// Creates [Logger] instances for a given category.
///
/// Providers are the pluggable sinks in the PurpleLogger pipeline.
/// Each provider decides how to handle log events (console, file, OTel, etc.).
///
/// ```dart
/// final class SyslogProvider implements LoggerProvider {
///   @override
///   Logger createLogger(String category) => SyslogLogger(category: category);
///
///   @override
///   void dispose() { /* close socket */ }
/// }
/// ```
abstract class LoggerProvider {
  const LoggerProvider();

  /// Creates a [Logger] for the given [category].
  Logger createLogger(String category);

  /// Releases resources held by this provider.
  ///
  /// The default implementation does nothing; override if needed.
  void dispose() {}
}