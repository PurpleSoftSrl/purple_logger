import 'logger.dart';
import 'logger_provider.dart';

/// Factory that creates [Logger] instances and manages the provider pipeline.
///
/// Obtain via [LoggingBuilder.build].
abstract interface class LoggerFactory {
  /// Creates a [Logger] for the given [category].
  Logger createLogger(String category);

  /// Adds a provider to the pipeline at runtime.
  ///
  /// Most users configure providers via [LoggingBuilder] instead.
  void addProvider(LoggerProvider provider);

  /// Releases all resources held by the factory and its providers.
  void dispose();
}