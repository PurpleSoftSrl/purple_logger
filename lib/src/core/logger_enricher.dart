import 'dart:io' show Platform, pid;

/// Immutable collection of properties automatically merged into every
/// [LogEvent] emitted by a [LoggerFactory].
///
/// Use [LoggerEnricher.fromEnvironment] to populate with hostname, PID,
/// and application metadata. Multiple enrichers can be composed via [merge].
final class LoggerEnricher {
  final Map<String, Object?> _properties;

  LoggerEnricher._(Map<String, Object?> properties)
      : _properties = Map.unmodifiable(properties);

  /// Creates an enricher from the given [properties] map.
  factory LoggerEnricher(Map<String, Object?> properties) {
    final enriched = <String, Object?>{};
    enriched.addAll(properties);
    return LoggerEnricher._(enriched);
  }

  /// Creates an enricher populated from the runtime environment.
  ///
  /// When [includeHostname] is `true`, reads [Platform.localHostname].
  /// When [includePid] is `true`, reads the process ID.
  /// Optional [appName], [appVersion], and [environment] are included
  /// when non-null.
  factory LoggerEnricher.fromEnvironment({
    bool includeHostname = true,
    bool includePid = true,
    String? appName,
    String? appVersion,
    String? environment,
  }) {
    final props = <String, Object?>{};
    try {
      if (includeHostname) {
        props['hostname'] = Platform.localHostname;
      }
      if (includePid) {
        props['pid'] = pid;
      }
    } catch (_) {
      if (includeHostname) {
        props['hostname'] = 'unknown';
      }
    }
    if (appName != null) {
      props['appName'] = appName;
    }
    if (appVersion != null) {
      props['appVersion'] = appVersion;
    }
    if (environment != null) {
      props['environment'] = environment;
    }
    return LoggerEnricher._(props);
  }

  /// The enriched properties (unmodifiable).
  Map<String, Object?> get properties => _properties;

  /// Returns a new [LoggerEnricher] with properties from both `this` and
  /// [other].
  ///
  /// [other] properties take precedence over `this` for duplicate keys.
  LoggerEnricher merge(LoggerEnricher other) {
    final merged = Map<String, Object?>.from(_properties);
    merged.addAll(other._properties);
    return LoggerEnricher._(merged);
  }
}
