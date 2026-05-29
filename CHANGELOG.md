## 2.1.5


## 2.1.4


## 2.1.3


## 2.0.0

- Complete rewrite — no dependency on `package:logging`
- Provider pipeline: multiple sinks running simultaneously
- Zone-based `LoggingScope` for async-safe contextual properties
- `LogEvent` as single immutable allocation shared across all providers
- `FilterRuleSet` with global + per-category + per-provider level control
- `LoggingBuilder` fluent API with logger caching
- Console, Debug, Memory, Null provider implementations
- SimpleFormatter (human-readable) and JsonFormatter (machine-parseable)
- `LoggerConvenience` mixin for trace/debug/info/warning/error/fatal methods
- `LoggerTagExtension` for tag-based classification
- `LoggerExceptionExtension` for auto errorType/errorMessage
- `HttpLogInterceptor` framework-agnostic HTTP logging
- `TimestampProvider` with injectable clock and fake for testing
- `MemoryLogStore` with rich query API and bounded capacity
- `PurpleLogger.quick()` one-liner convenience

## 2.1.0

- `FileLoggerProvider` with size-based rotation, async buffered writes, optional gzip
- `LoggerEnricher` — auto-inject hostname, pid, appName, appVersion, environment
- Environment variable configuration: `PLOG_LEVEL`, `PLOG_FORMAT`, `PLOG_OUTPUT`, `PLOG_FILE_PATH`
- `LoggingBuilder.fromEnvironment()` factory
- `LoggerFactory` runtime reconfiguration: `setMinimumLevel()`, `addFilterRule()`, `removeFilterRule()`
- `LoggingBuilder.enrichWith()` for contextual properties
