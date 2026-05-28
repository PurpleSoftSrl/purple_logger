import 'dart:io' show Platform, pid;

final class LoggerEnricher {
  final Map<String, Object?> _properties;

  LoggerEnricher._(Map<String, Object?> properties)
      : _properties = Map.unmodifiable(properties);

  factory LoggerEnricher(Map<String, Object?> properties) {
    final enriched = <String, Object?>{};
    enriched.addAll(properties);
    return LoggerEnricher._(enriched);
  }

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

  Map<String, Object?> get properties => _properties;

  LoggerEnricher merge(LoggerEnricher other) {
    final merged = Map<String, Object?>.from(_properties);
    merged.addAll(other._properties);
    return LoggerEnricher._(merged);
  }
}
