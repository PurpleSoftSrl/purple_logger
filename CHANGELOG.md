## 2.0.0

- **Complete rewrite** from v1 to v2.
- Removed `package:logging` dependency.
- Provider pipeline architecture (Console, Debug, Memory, Null, Custom).
- Structured properties kept separate from messages.
- Zone-based `LoggingScope` with async-safe nested chaining.
- `FilterRuleSet` with per-category and per-provider overrides.
- `LoggerConvenience` mixin for zero-boilerplate level methods.
- `EventLogger` interface for receiving assembled `LogEvent`s.
- `SimpleFormatter` and `JsonFormatter` out of the box.
- `MemoryLogStore` with rich query methods for testing.
- `LoggerTagExtension` for tag-based logging.
- `LoggerExceptionExtension` for auto-derived error properties.
- `HttpLogInterceptor` for framework-agnostic HTTP logging.
- `PurpleLogger.quick()` one-liner static entry point.
- `LoggingBuilder` fluent API.
- Zero-alloc guard when level is disabled.
- OpenTelemetry-ready (bridge via `purple_logger_otel` companion package).

## 1.0.0

- Initial release based on `package:logging`.