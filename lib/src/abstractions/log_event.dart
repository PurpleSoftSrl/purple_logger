import 'log_level.dart';

/// An immutable log event carrying all information for a single log entry.
///
/// A single [LogEvent] is allocated per [Logger.log] call and shared across
/// all providers — zero redundant allocations.
final class LogEvent {
  /// Severity level of this event.
  final PurpleLogLevel level;

  /// Category (logger name) that produced this event.
  final String category;

  /// Human-readable log message.
  final String message;

  /// Wall-clock time when the event was created.
  final DateTime timestamp;

  /// Caller-supplied structured key-value pairs.
  final Map<String, Object?> properties;

  /// Contextual properties merged from the [LoggingScope] chain.
  final Map<String, Object?> scopeProperties;

  /// Associated error object, if any.
  final Object? error;

  /// Stack trace associated with [error], if any.
  final StackTrace? stackTrace;

  LogEvent({
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    Map<String, Object?>? properties,
    Map<String, Object?>? scopeProperties,
    this.error,
    this.stackTrace,
  })  : properties = _freeze(properties),
        scopeProperties = _freeze(scopeProperties);

  /// Returns a copy with optional field overrides.
  LogEvent copyWith({
    PurpleLogLevel? level,
    String? category,
    String? message,
    DateTime? timestamp,
    Map<String, Object?>? properties,
    Map<String, Object?>? scopeProperties,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      LogEvent(
        level: level ?? this.level,
        category: category ?? this.category,
        message: message ?? this.message,
        timestamp: timestamp ?? this.timestamp,
        properties: properties ?? Map<String, Object?>.of(this.properties),
        scopeProperties:
            scopeProperties ?? Map<String, Object?>.of(this.scopeProperties),
        error: error ?? this.error,
        stackTrace: stackTrace ?? this.stackTrace,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEvent &&
          level == other.level &&
          category == other.category &&
          message == other.message &&
          timestamp == other.timestamp &&
          _mapEq(properties, other.properties) &&
          _mapEq(scopeProperties, other.scopeProperties) &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        level,
        category,
        message,
        timestamp,
        Object.hashAllUnordered(properties.entries),
        Object.hashAllUnordered(scopeProperties.entries),
        error,
      );

  @override
  String toString() =>
      'LogEvent($level, $category, $message${error != null ? ', error: $error' : ''})';

  // ── Internal helpers ─────────────────────────────────────────────────────

  static Map<String, Object?> _freeze(Map<String, Object?>? map) =>
      map == null || map.isEmpty
          ? const {}
          : Map<String, Object?>.unmodifiable(Map.of(map));

  static bool _mapEq(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
