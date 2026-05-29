import '../abstractions/log_level.dart';
import '../abstractions/logger_provider.dart';
import '../core/filter_rules.dart';
import 'logger.dart';

/// Central registry that creates and manages [Logger] instances.
///
/// Providers registered via [addProvider] form a pipeline: each [Logger.log]
/// call is routed through every provider's [EventLogger.write] (if the event
/// passes filtering). Use [LoggingBuilder] to configure and build a
/// [LoggerFactory] instance.
///
/// ```dart
/// final factory = LoggingBuilder()
///   .addConsole()
///   .setMinimumLevel(PurpleLogLevel.info)
///   .build();
/// final logger = factory.createLogger('MyApp');
/// ```
abstract interface class LoggerFactory {
  /// Creates a [Logger] for the given [category].
  ///
  /// The returned logger routes events through all registered providers.
  Logger createLogger(String category);

  /// Registers a [LoggerProvider] that will receive all future log events.
  void addProvider(LoggerProvider provider);

  /// Disposes all registered providers and releases internal resources.
  void dispose();

  /// Sets the minimum global level threshold.
  ///
  /// Events below this level are discarded before reaching any provider.
  /// Equivalent to calling [setGlobalLevel].
  void setMinimumLevel(PurpleLogLevel level);

  /// Sets the global minimum level applied to all providers.
  ///
  /// Use [addFilterRule] for per-provider or per-category overrides.
  void setGlobalLevel(PurpleLogLevel level);

  /// Adds a [FilterRule] that overrides the minimum level for matching
  /// provider/category combinations.
  ///
  /// Rules are evaluated in specificity order (most specific wins).
  void addFilterRule(FilterRule rule);

  /// Removes a previously added [FilterRule].
  void removeFilterRule(FilterRule rule);
}
