import 'dart:async';

/// A Zone-based logging scope that carries contextual properties through
/// an entire async call chain.
///
/// Scopes nest: child properties override parent properties with the same key.
/// The scope is released automatically when [run] or [runAsync] completes.
///
/// ```dart
/// final scope = logger.beginScope({'requestId': 'abc-123'});
/// await scope.runAsync(() async {
///   logger.info('Processing');   // includes requestId
///   await callDownstream();
///   logger.info('Done');         // still includes requestId
/// });
/// ```
final class LoggingScope {
  static final _scopeKey = Object();

  /// Properties attached to this scope.
  final Map<String, Object?> properties;

  /// Parent scope in the chain, if any.
  final LoggingScope? _parent;

  /// Creates a scope with the given [properties] and optional [_parent].
  LoggingScope(this.properties, [this._parent]);

  /// The effective properties merged from the entire scope chain.
  ///
  /// Child properties override parent properties with the same key.
  Map<String, Object?> get effectiveProperties {
    if (_parent == null) return Map<String, Object?>.of(properties);
    final merged = Map<String, Object?>.of(_parent.effectiveProperties);
    merged.addAll(properties);
    return merged;
  }

  /// Runs [body] synchronously with this scope active in the current Zone.
  ///
  /// If a parent scope is already active, this scope chains to it so that
  /// [effectiveProperties] merges both.
  T run<T>(T Function() body) {
    final parentScope = Zone.current[_scopeKey];
    final effectiveScope = parentScope is LoggingScope
        ? LoggingScope(properties, parentScope)
        : this;
    return runZoned(body, zoneValues: {_scopeKey: effectiveScope});
  }

  /// Runs [body] asynchronously with this scope active in the current Zone.
  ///
  /// If a parent scope is already active, this scope chains to it so that
  /// [effectiveProperties] merges both.
  Future<T> runAsync<T>(Future<T> Function() body) {
    final parentScope = Zone.current[_scopeKey];
    final effectiveScope = parentScope is LoggingScope
        ? LoggingScope(properties, parentScope)
        : this;
    return runZoned(body, zoneValues: {_scopeKey: effectiveScope});
  }

  /// Retrieves the active [LoggingScope] from the current Zone, or `null`.
  static LoggingScope? get current {
    final scope = Zone.current[_scopeKey];
    return scope is LoggingScope ? scope : null;
  }

  /// Returns the merged scope properties from the current Zone chain,
  /// or an empty map if no scope is active.
  static Map<String, Object?> get currentProperties {
    final scope = current;
    return scope?.effectiveProperties ?? const {};
  }
}
