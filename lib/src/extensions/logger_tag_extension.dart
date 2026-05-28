import '../abstractions/logger.dart';
import '../abstractions/log_level.dart';

/// Extension that adds tag-based logging to [Logger].
///
/// Tags provide a lightweight secondary classification for log entries,
/// orthogonal to category and level. Tags are stored under the reserved
/// property key [tagKey] (`'tag'`).
///
/// ```dart
/// logger.infoTagged('auth', 'User signed in', properties: {'userId': 42});
/// ```
extension LoggerTagExtension on Logger {
  /// Reserved property key for tags.
  static const tagKey = 'tag';

  /// Emits a tagged log entry at [level].
  void logTagged(
    PurpleLogLevel level,
    String tag,
    Object? message, {
    Map<String, Object?>? properties,
  }) {
    final merged = <String, Object?>{tagKey: tag};
    if (properties != null) merged.addAll(properties);
    log(level, message, properties: merged);
  }

  /// Tagged [PurpleLogLevel.trace].
  void traceTagged(String tag, Object? message,
          {Map<String, Object?>? properties}) =>
      logTagged(PurpleLogLevel.trace, tag, message, properties: properties);

  /// Tagged [PurpleLogLevel.debug].
  void debugTagged(String tag, Object? message,
          {Map<String, Object?>? properties}) =>
      logTagged(PurpleLogLevel.debug, tag, message, properties: properties);

  /// Tagged [PurpleLogLevel.info].
  void infoTagged(String tag, Object? message,
          {Map<String, Object?>? properties}) =>
      logTagged(PurpleLogLevel.info, tag, message, properties: properties);

  /// Tagged [PurpleLogLevel.warning].
  void warningTagged(String tag, Object? message,
          {Map<String, Object?>? properties}) =>
      logTagged(PurpleLogLevel.warning, tag, message, properties: properties);

  /// Tagged [PurpleLogLevel.error].
  void errorTagged(
    String tag,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  }) =>
      log(
        PurpleLogLevel.error,
        message,
        properties: _withTag(tag, properties),
        error: error,
        stackTrace: stackTrace,
      );

  /// Tagged [PurpleLogLevel.fatal].
  void fatalTagged(
    String tag,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  }) =>
      log(
        PurpleLogLevel.fatal,
        message,
        properties: _withTag(tag, properties),
        error: error,
        stackTrace: stackTrace,
      );

  Map<String, Object?> _withTag(String tag, Map<String, Object?>? props) {
    final merged = <String, Object?>{LoggerTagExtension.tagKey: tag};
    if (props != null) merged.addAll(props);
    return merged;
  }
}
