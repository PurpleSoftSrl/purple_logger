import 'dart:io' show Platform;

import '../abstractions/log_level.dart';

final class EnvLoggingConfig {
  final PurpleLogLevel minimumLevel;
  final String? logFormat;
  final String? logOutput;
  final String? filePath;

  const EnvLoggingConfig({
    PurpleLogLevel? minimumLevel,
    this.logFormat,
    this.logOutput,
    this.filePath,
  }) : minimumLevel = minimumLevel ?? PurpleLogLevel.info;

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
      case 'trace': return PurpleLogLevel.trace;
      case 'debug': return PurpleLogLevel.debug;
      case 'info': return PurpleLogLevel.info;
      case 'warning': return PurpleLogLevel.warning;
      case 'error': return PurpleLogLevel.error;
      case 'fatal': return PurpleLogLevel.fatal;
      case 'none': return PurpleLogLevel.none;
      default: return PurpleLogLevel.info;
    }
  }
}
