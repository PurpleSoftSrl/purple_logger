import 'log_level.dart';
import 'logging_scope.dart';

/// Core logger interface for PurpleLogger.
///
/// Provides leveled, structured logging with scope support.
/// Obtain instances via [LoggerFactory.createLogger].
///
/// ```dart
/// final logger = factory.createLogger('OrderService');
/// logger.info('Order placed', properties: {'orderId': 1042});
/// ```
abstract interface class Logger {
  /// Category name (e.g. 'OrderService', 'PurpleTTS.Engine').
  String get category;

  /// Returns `true` if [level] would be emitted by at least one provider.
  ///
  /// Use this as a zero-alloc guard before constructing expensive messages:
  /// ```dart
  /// if (logger.isEnabled(PurpleLogLevel.debug)) {
  ///   logger.debug('Snapshot: ${expensiveDump()}');
  /// }
  /// ```
  bool isEnabled(PurpleLogLevel level);

  /// Emits a log entry at [level].
  ///
  /// [properties] are structured key-value pairs kept separate from the
  /// message so providers can decide how to render them.
  void log(
    PurpleLogLevel level,
    Object? message, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  });

  /// Begins a new logging scope with the given [properties].
  ///
  /// Scope properties are automatically merged into every log event emitted
  /// within [LoggingScope.run] / [LoggingScope.runAsync].
  LoggingScope beginScope(Map<String, Object?> properties);

  /// Log at [PurpleLogLevel.trace].
  void trace(Object? message, {Map<String, Object?>? properties});

  /// Log at [PurpleLogLevel.debug].
  void debug(Object? message, {Map<String, Object?>? properties});

  /// Log at [PurpleLogLevel.info].
  void info(Object? message, {Map<String, Object?>? properties});

  /// Log at [PurpleLogLevel.warning].
  void warning(Object? message, {Map<String, Object?>? properties});

  /// Log at [PurpleLogLevel.error].
  void error(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  });

  /// Log at [PurpleLogLevel.fatal].
  void fatal(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  });
}

/// Mixin that provides default implementations for all convenience methods
/// on [Logger] by delegating to [log].
///
/// Any class that `implements Logger` and overrides [log] can mix this in
/// to get all the convenience methods for free.
mixin LoggerConvenience implements Logger {
  @override
  void trace(Object? message, {Map<String, Object?>? properties}) =>
      log(PurpleLogLevel.trace, message, properties: properties);

  @override
  void debug(Object? message, {Map<String, Object?>? properties}) =>
      log(PurpleLogLevel.debug, message, properties: properties);

  @override
  void info(Object? message, {Map<String, Object?>? properties}) =>
      log(PurpleLogLevel.info, message, properties: properties);

  @override
  void warning(Object? message, {Map<String, Object?>? properties}) =>
      log(PurpleLogLevel.warning, message, properties: properties);

  @override
  void error(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  }) =>
      log(
        PurpleLogLevel.error,
        message,
        properties: properties,
        error: error,
        stackTrace: stackTrace,
      );

  @override
  void fatal(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  }) =>
      log(
        PurpleLogLevel.fatal,
        message,
        properties: properties,
        error: error,
        stackTrace: stackTrace,
      );
}
