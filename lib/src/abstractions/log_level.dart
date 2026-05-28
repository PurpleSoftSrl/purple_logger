/// Log severity levels for PurpleLogger.
///
/// Ordered from least severe ([PurpleLogLevel.trace]) to most severe
/// ([PurpleLogLevel.fatal]). The sentinel [PurpleLogLevel.none] suppresses
/// all output.
///
/// Maps to OpenTelemetry's 24-level severity scale via
/// [PurpleLogLevel.severityNumber].
enum PurpleLogLevel {
  /// Finest-grained debugging — method entry/exit, internal state.
  trace,

  /// Developer diagnostics — useful during development.
  debug,

  /// Normal operational milestones — startup, requests, etc.
  info,

  /// Recoverable, unexpected situations that deserve attention.
  warning,

  /// Failures preventing the current operation from completing.
  error,

  /// Unrecoverable failures requiring immediate intervention.
  fatal,

  /// Sentinel — disables all output for the target scope.
  none;

  /// Short label used by formatters (4 chars, uppercase).
  String get label => switch (this) {
        trace   => 'TRCE',
        debug   => 'DBUG',
        info    => 'INFO',
        warning => 'WARN',
        error   => 'EROR',
        fatal   => 'CRIT',
        none    => 'NONE',
      };

  /// OpenTelemetry SeverityNumber per the OTel Logs data model.
  ///
  /// See: https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-severitynumber
  int get severityNumber => switch (this) {
        trace   => 1,  // TRACE
        debug   => 5,  // DEBUG
        info    => 9,  // INFO
        warning => 13, // WARN
        error   => 17, // ERROR
        fatal   => 21, // FATAL
        none    => 0,  // unset
      };

  /// OpenTelemetry severity text per the OTel spec.
  String get severityText => switch (this) {
        trace   => 'TRACE',
        debug   => 'DEBUG',
        info    => 'INFO',
        warning => 'WARN',
        error   => 'ERROR',
        fatal   => 'FATAL',
        none    => '',
      };

  /// Returns `true` if this level is at least as severe as [minimum].
  bool isAtLeast(PurpleLogLevel minimum) =>
      this != none && (minimum == none || index >= minimum.index);

  /// Returns `true` when this level is [none] (suppresses all output).
  bool get isNone => this == none;
}