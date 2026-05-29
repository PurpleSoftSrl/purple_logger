import 'dart:collection';

import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';

/// [LoggerProvider] that stores all log events in memory.
///
/// Primarily intended for unit and integration tests.
///
/// ```dart
/// final store = MemoryLogStore();
/// final factory = LoggingBuilder()
///   .addMemory(store: store)
///   .setMinimumLevel(PurpleLogLevel.trace)
///   .build();
/// ```
final class MemoryLoggerProvider extends LoggerProvider {
  final MemoryLogStore store;

  MemoryLoggerProvider({MemoryLogStore? store})
      : store = store ?? MemoryLogStore();

  @override
  Logger createLogger(String category) =>
      MemoryLogger(category: category, store: store);

  @override
  void dispose() {
    store.clear();
  }
}

/// [EventLogger] that appends events to a [MemoryLogStore].
final class MemoryLogger with LoggerConvenience implements EventLogger {
  /// Logger category name.
  @override
  final String category;

  /// The [MemoryLogStore] that receives log events.
  final MemoryLogStore store;

  MemoryLogger({required this.category, required this.store});

  @override
  bool isEnabled(PurpleLogLevel level) => !level.isNone;

  @override
  void write(LogEvent event) => store.add(event);

  @override
  void log(
    PurpleLogLevel level,
    Object? message, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  LoggingScope beginScope(Map<String, Object?> properties) =>
      LoggingScope(properties);
}

/// In-memory store for log events with rich query capabilities.
///
/// Supports optional bounded capacity with FIFO eviction.
///
/// ```dart
/// final store = MemoryLogStore(maxCapacity: 1000);
/// // ... logging activity ...
/// final errors = store.eventsAtOrAbove(PurpleLogLevel.error);
/// print(store.exportAsJson());
/// ```
final class MemoryLogStore {
  /// Maximum number of events to retain; `null` for unbounded.
  final int? maxCapacity;
  final ListQueue<LogEvent> _events = ListQueue<LogEvent>();

  /// Creates a [MemoryLogStore] with an optional [maxCapacity].
  MemoryLogStore({this.maxCapacity});

  /// Appends [event] to the store, evicting the oldest if at capacity.
  void add(LogEvent event) {
    if (maxCapacity != null && _events.length >= maxCapacity!) {
      _events.removeFirst();
    }
    _events.addLast(event);
  }

  /// All stored events (unmodifiable).
  List<LogEvent> get events => List.unmodifiable(_events);

  /// Total event count.
  int get length => _events.length;

  /// `true` when no events are stored.
  bool get isEmpty => _events.isEmpty;

  /// `true` when at least one event is stored.
  bool get isNotEmpty => _events.isNotEmpty;

  /// Events at or above [minimum] severity.
  List<LogEvent> eventsAtOrAbove(PurpleLogLevel minimum) =>
      List.unmodifiable(_events.where((e) => e.level.isAtLeast(minimum)));

  /// Events from a specific [category].
  List<LogEvent> eventsForCategory(String category) =>
      List.unmodifiable(_events.where((e) => e.category == category));

  /// Events whose `properties['tag']` equals [tag].
  List<LogEvent> eventsForTag(String tag) => List.unmodifiable(
        _events.where((e) => e.properties['tag'] == tag),
      );

  /// Exports all events as a JSON string.
  ///
  /// Format: one JSON object per event in a JSON array.
  String exportAsJson() {
    if (_events.isEmpty) return '[]';
    final items = _events.map(_eventToJson).join(',');
    return '[$items]';
  }

  /// Removes all stored events.
  void clear() => _events.clear();

  String _eventToJson(LogEvent e) {
    final buf = StringBuffer('{');
    buf.write('"timestamp":"${e.timestamp.toIso8601String()}"');
    buf.write(',"level":"${e.level.name}"');
    buf.write(',"category":"${_escape(e.category)}"');
    buf.write(',"message":"${_escape(e.message)}"');
    if (e.properties.isNotEmpty) {
      buf.write(',"properties":${_mapToJson(e.properties)}');
    }
    if (e.scopeProperties.isNotEmpty) {
      buf.write(',"scopeProperties":${_mapToJson(e.scopeProperties)}');
    }
    if (e.error != null) {
      buf.write(',"error":"${_escape(e.error.toString())}"');
    }
    if (e.stackTrace != null) {
      buf.write(',"stackTrace":"${_escape(e.stackTrace.toString())}"');
    }
    buf.write('}');
    return buf.toString();
  }

  String _mapToJson(Map<String, Object?> map) {
    final entries = map.entries
        .map((e) => '"${_escape(e.key)}":${_valueToJson(e.value)}')
        .join(',');
    return '{$entries}';
  }

  String _valueToJson(Object? v) {
    if (v == null) return 'null';
    if (v is String) return '"${_escape(v)}"';
    if (v is bool || v is num) return v.toString();
    return '"${_escape(v.toString())}"';
  }

  String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');
}
