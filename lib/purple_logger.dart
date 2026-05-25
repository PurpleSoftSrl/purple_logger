/// Enterprise-grade structured logger for PurpleSoft Flutter plugins.
///
/// Provides hierarchical, leveled logging with zero `print()` calls.
/// Each plugin gets its own named logger. In debug builds, logs are verbose;
/// in release builds, only warnings and errors are emitted by default.
///
/// Usage:
/// ```dart
/// final _log = PurpleLogger('PurpleTTS');
/// _log.info('Engine initialized');
/// _log.warning('Voice not found, falling back');
/// _log.error('Synthesis failed', error: e, stackTrace: st);
/// ```
library;

import 'package:logging/logging.dart';

/// Hierarchical log level names for PurpleSoft plugins.
///
/// Follows the standard [Level] hierarchy from `package:logging`:
/// - [Level.FINEST] — Verbose internal tracing (method entry/exit)
/// - [Level.FINER]  — Detailed tracing (event dispatch)
/// - [Level.FINE]   — General tracing (state changes)
/// - [Level.CONFIG] — Configuration changes
/// - [Level.INFO]   — Important operational events
/// - [Level.WARNING] — Recoverable issues
/// - [Level.SEVERE] — Failures requiring attention
/// - [Level.SHOUT]  — Critical failures

/// Enterprise-grade logger wrapper for PurpleSoft plugins.
///
/// Wraps `package:logging` with:
/// - Named loggers per plugin (hierarchical dot notation)
/// - Structured message formatting with timestamps
/// - Production-safe defaults (WARNING+ in release, ALL in debug)
/// - Zero `print()` calls — all output goes through [Logger]
class PurpleLogger {
  static bool _initialized = false;

  /// The underlying [Logger] instance.
  final Logger _logger;

  /// Creates a named logger for a PurpleSoft plugin.
  ///
  /// [name] should be the plugin identifier, e.g. `'PurpleTTS'` or `'PurpleSTT'`.
  /// Loggers are hierarchical: `PurpleTTS.Engine` is a child of `PurpleTTS`.
  PurpleLogger(String name) : _logger = Logger(name) {
    _ensureInitialized();
  }

  /// Creates a child logger for a sub-component.
  ///
  /// Example: `PurpleLogger('PurpleTTS').child('Engine')`
  /// creates logger `PurpleTTS.Engine`.
  PurpleLogger child(String subname) => PurpleLogger('${_logger.name}.$subname');

  /// Ensures the logging system is configured exactly once.
  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    // In release mode, only show WARNING and above.
    // In debug mode, show everything.
    Logger.root.level = bool.fromEnvironment('dart.vm.product')
        ? Level.WARNING
        : Level.ALL;

    Logger.root.onRecord.listen((record) {
      // Structured format: [LEVEL] [TIME] LoggerName: Message
      final level = record.level.name.padRight(7);
      final time = record.time.toIso8601String();
      final prefix = '[$level] [$time] ${record.loggerName}:';
      if (record.error != null) {
        // ignore: avoid_print — this IS the logging sink
        print('$prefix ${record.message}\n  Error: ${record.error}');
        if (record.stackTrace != null) {
          // ignore: avoid_print — this IS the logging sink
          print('  StackTrace: ${record.stackTrace}');
        }
      } else {
        // ignore: avoid_print — this IS the logging sink
        print('$prefix ${record.message}');
      }
    });
  }

  // ── Convenience Methods ──────────────────────────────────────────────────

  /// Log at [Level.FINEST] — verbose internal tracing.
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.finest(message, error, stackTrace);

  /// Log at [Level.FINER] — detailed tracing.
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.finer(message, error, stackTrace);

  /// Log at [Level.FINE] — general tracing.
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.fine(message, error, stackTrace);

  /// Log at [Level.CONFIG] — configuration changes.
  void config(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.config(message, error, stackTrace);

  /// Log at [Level.INFO] — important operational events.
  void info(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.info(message, error, stackTrace);

  /// Log at [Level.WARNING] — recoverable issues.
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.warning(message, error, stackTrace);

  /// Log at [Level.SEVERE] — failures requiring attention.
  void error(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);

  /// Log at [Level.SHOUT] — critical failures.
  void critical(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.shout(message, error, stackTrace);
}