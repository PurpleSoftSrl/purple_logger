import 'dart:io' show Platform;

import '../abstractions/log_level.dart';

/// Configuration parsed from environment variables for use by
/// [LoggingBuilder.fromEnvironment].
///
/// Reads the following variables:
/// - `PLOG_LEVEL`: minimum log level (trace, debug, info, warning, error, fatal, none)
/// - `PLOG_FORMAT`: output format (`json` or `simple`)
/// - `PLOG_OUTPUT`: output target (`console`, `file`, `both`)
/// - `PLOG_FILE_PATH`: file path when `PLOG_OUTPUT` is `file` or `both`
final class EnvLoggingConfig {
  /// Minimum log level parsed from `PLOG_LEVEL`, defaults to [PurpleLogLevel.info].
  final PurpleLogLevel minimumLevel;

  /// Output format: `json` or `simple` (null = simple/console default).
  final String? logFormat;

  /// Output target: `console`, `file`, or `both` (null = console).
  final String? logOutput;

  /// File path for file-based output.
  final String? filePath;

  /// Creates an [EnvLoggingConfig] with the given values.
  const EnvLoggingConfig({
    PurpleLogLevel? minimumLevel,
    this.logFormat,
    this.logOutput,
    this.filePath,
  }) : minimumLevel = minimumLevel ?? PurpleLogLevel.info;

  /// Reads configuration from [Platform.environment].
  ///
  /// [overrides] can be used to supply values in tests, taking precedence
  /// over real environment variables.
  factory EnvLoggingConfig.fromEnvironment({Map<String, String>? overrides}) {
    final env = <String, String>{};
    try {
      final platformEnv = Platform.environment;
      env.addAll(platformEnv);
      if (overrides != null) env.addAll(overrides);
    } catch (_) {
      if (overrides != null) env.addAll(overrides);
    }

    return EnvLoggingConfig(
      minimumLevel: _parseLevel(env['PLOG_LEVEL']),
      logFormat: env['PLOG_FORMAT'],
      logOutput: env['PLOG_OUTPUT'],
      filePath: env['PLOG_FILE_PATH'],
    );
  }

  static PurpleLogLevel _parseLevel(String? value) {
    if (value == null) return PurpleLogLevel.info;
    switch (value.toLowerCase()) {
      case 'trace':
        return PurpleLogLevel.trace;
      case 'debug':
        return PurpleLogLevel.debug;
      case 'info':
        return PurpleLogLevel.info;
      case 'warning':
        return PurpleLogLevel.warning;
      case 'error':
        return PurpleLogLevel.error;
      case 'fatal':
        return PurpleLogLevel.fatal;
      case 'none':
        return PurpleLogLevel.none;
      default:
        return PurpleLogLevel.info;
    }
  }
}
