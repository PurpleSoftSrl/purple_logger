import '../abstractions/log_formatter.dart';
import '../core/logging_builder.dart';
import '../providers/console_logger.dart';
import '../providers/debug_logger.dart';
import '../providers/memory_logger.dart';

/// Extension methods on [LoggingBuilder] for built-in providers.
extension LoggingBuilderExtensions on LoggingBuilder {
  /// Adds a [ConsoleLoggerProvider] with optional [formatter].
  LoggingBuilder addConsole({LogFormatter? formatter}) =>
      addProvider(ConsoleLoggerProvider(formatter: formatter));

  /// Adds a [DebugLoggerProvider] (writes to dart:developer.log).
  LoggingBuilder addDebug() => addProvider(DebugLoggerProvider());

  /// Adds a [MemoryLoggerProvider] with optional [store].
  LoggingBuilder addMemory({MemoryLogStore? store}) =>
      addProvider(MemoryLoggerProvider(store: store));
}
