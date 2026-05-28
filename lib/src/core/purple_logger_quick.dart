import '../abstractions/logger.dart';
import '../abstractions/logger_factory.dart';
import '../abstractions/log_level.dart';
import '../core/logging_builder.dart';
import '../providers/console_logger.dart';

/// Static helper for quick logger creation without a full [LoggingBuilder] setup.
///
/// All three entry points share a single internal [ConsoleLoggerProvider]-backed
/// factory that is rebuilt automatically if the minimum level changes.
///
/// ```dart
/// // Single logger with default category and level
/// final log = PurpleLogger.quick();
///
/// // Named category + custom minimum level
/// final serviceLog = PurpleLogger.quick(
///   category: 'OrderService',
///   minimumLevel: PurpleLogLevel.warning,
/// );
///
/// // Deterministic cleanup (recommended at shutdown)
/// PurpleLogger.disposeQuickFactory();
/// ```
final class PurpleLogger {
  static LoggerFactory? _quickFactory;

  PurpleLogger._();

  /// Returns a [Logger] with default category ('App') and level (debug+).
  static Logger quick({
    String category = 'App',
    PurpleLogLevel minimumLevel = PurpleLogLevel.debug,
  }) {
    _ensureFactory(minimumLevel);
    return _quickFactory!.createLogger(category);
  }

  /// Returns a shared [LoggerFactory] with the given [minimumLevel].
  static LoggerFactory quickFactory({
    PurpleLogLevel minimumLevel = PurpleLogLevel.debug,
  }) {
    _ensureFactory(minimumLevel);
    return _quickFactory!;
  }

  /// Disposes the shared quick factory.
  ///
  /// After calling this, the next [quick] or [quickFactory] call
  /// automatically rebuilds the factory.
  static void disposeQuickFactory() {
    _quickFactory?.dispose();
    _quickFactory = null;
  }

  static void _ensureFactory(PurpleLogLevel minimumLevel) {
    if (_quickFactory != null) return;
    _quickFactory = LoggingBuilder()
        .addProvider(ConsoleLoggerProvider())
        .setMinimumLevel(minimumLevel)
        .build();
  }
}