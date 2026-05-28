/// Enterprise-grade structured logger for Dart and Flutter.
///
/// PurpleLogger provides hierarchical, leveled, structured logging with:
/// - **Provider pipeline**: Multiple sinks (Console, Debug, Memory, Null, Custom)
///   running simultaneously
/// - **Structured properties**: Key-value pairs kept separate from messages
/// - **Zone-based scopes**: Async-safe contextual properties that propagate
///   through the entire call chain
/// - **Filter rules**: Global + per-category + per-provider level control
/// - **Zero-alloc guards**: `isEnabled()` exits before any object allocation
/// - **Formatters**: Simple (human-readable) and JSON out of the box
/// - **MemoryLogStore**: In-memory store with rich query methods for testing
/// - **Tag-based logging**: Lightweight secondary classification
/// - **Exception helper**: Auto-derived `errorType`/`errorMessage` properties
/// - **HTTP interceptor**: Framework-agnostic request/response/error logging
/// - **OpenTelemetry bridge**: Via the `purple_logger_otel` companion package
///
/// ## Quick start
///
/// ```dart
/// // One-liner
/// final log = PurpleLogger.quick();
/// log.info('Application started');
///
/// // Full setup
/// final factory = LoggingBuilder()
///   .addConsole()
///   .setMinimumLevel(PurpleLogLevel.info)
///   .build();
/// final logger = factory.createLogger('MyApp');
/// logger.info('Order placed', properties: {'orderId': 1042});
/// factory.dispose();
/// ```
///
/// Named after Argus Panoptes — the all-seeing guardian of Greek mythology.
/// Every event, every error, every trace — nothing escapes PurpleLogger.
library;

// ── Abstractions ────────────────────────────────────────────────────────────
export 'src/abstractions/event_logger.dart';
export 'src/abstractions/log_event.dart';
export 'src/abstractions/log_formatter.dart';
export 'src/abstractions/log_level.dart';
export 'src/abstractions/logger.dart';
export 'src/abstractions/logger_factory.dart';
export 'src/abstractions/logger_provider.dart';
export 'src/abstractions/logging_scope.dart';

// ── Core ────────────────────────────────────────────────────────────────────
export 'src/core/filter_rules.dart';
export 'src/core/logging_builder.dart';
export 'src/core/logger_enricher.dart';
export 'src/core/env_logging_config.dart';
export 'src/core/logger_factory_impl.dart';
export 'src/core/logger_impl.dart';
export 'src/core/purple_logger_quick.dart';

// ── Providers ────────────────────────────────────────────────────────────────
export 'src/providers/console_logger.dart';
export 'src/providers/debug_logger.dart';
export 'src/providers/file_logger.dart';
export 'src/providers/memory_logger.dart';
export 'src/providers/null_logger.dart';

// ── Formatting ───────────────────────────────────────────────────────────────
export 'src/formatting/json_formatter.dart';
export 'src/formatting/simple_formatter.dart';

// ── Extensions ───────────────────────────────────────────────────────────────
export 'src/extensions/logger_exception_extension.dart';
export 'src/extensions/logger_tag_extension.dart';
export 'src/extensions/logging_builder_extensions.dart';

// ── Integrations ─────────────────────────────────────────────────────────────
export 'src/integrations/http_log_interceptor.dart';

// ── Utilities ─────────────────────────────────────────────────────────────────
export 'src/utils/timestamp_provider.dart';