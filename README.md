# PurpleLogger

[![Pub Version](https://img.shields.io/pub/v/purple_logger.svg)](https://pub.dev/packages/purple_logger)
[![License](https://img.shields.io/badge/license-AGPL%203.0-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.2.0-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.16.0-blue.svg)](https://flutter.dev)

Enterprise-grade structured logger for Dart and Flutter — provider pipeline, zone-based scopes, file rotation, OpenTelemetry integration, and zero-allocation guards.

## Features

### Core
- **Provider pipeline** — multiple sinks (Console, Debug, File, Memory, OTel) running simultaneously
- **7 severity levels** — trace, debug, info, warning, error, fatal + none
- **Structured properties** — key-value pairs kept separate from messages, never concatenated
- **Zone-based scopes** — async-safe contextual properties that propagate through the entire call chain
- **Zero-alloc guards** — `isEnabled()` check before any object allocation
- **Logger caching** — instances cached by category name

### Providers (Sinks)
| Provider | Output | Use Case |
|----------|--------|----------|
| `ConsoleLoggerProvider` | stdout with ANSI colors | Development, debugging |
| `DebugLoggerProvider` | `dart:developer.log()` | Flutter DevTools, web-safe |
| `FileLoggerProvider` | File with rotation | Production servers, audit logs |
| `MemoryLoggerProvider` | In-memory store | Testing, CI pipelines |
| `NullLoggerProvider` | Discard | Optional dependencies |
| `OtelLoggerProvider` | OpenTelemetry (via companion) | Observability backends |

### Enterprise
- **File rotation** — size-based rolling with configurable max files + optional gzip
- **Async buffered writes** — configurable flush interval for file output
- **Property enrichers** — auto-inject hostname, pid, appName, appVersion, environment
- **Environment variable config** — `PLOG_LEVEL`, `PLOG_FORMAT`, `PLOG_OUTPUT`, `PLOG_FILE_PATH`
- **Runtime reconfiguration** — `setMinimumLevel()`, `addFilterRule()`, `removeFilterRule()` without restart
- **Filter rules** — global + per-category-prefix + per-provider-type level control
- **OpenTelemetry bridge** — structured logs become OTel LogRecords with trace correlation

### Formatters
| Formatter | Output | Use Case |
|-----------|--------|----------|
| `SimpleFormatter` | `[INFO] Category >> Message {props}` | Human-readable, development |
| `JsonFormatter` | `{"timestamp":"...","level":"info","category":"...","message":"..."}` | Log aggregation, ELK, Loki |

### Extensions & Integrations
- **Tag-based logging** — `logger.infoTagged('auth', 'User logged in')`
- **Exception helper** — `logger.logException(e, st)` — auto `errorType`/`errorMessage` properties
- **HTTP interceptor** — framework-agnostic request/response/error logging
- **Timing** — `logger.beginTimed('operation')` → `logger.endTimed()` → duration in properties

### Testing Support
- **`MemoryLogStore`** — rich query API: `eventsAtOrAbove()`, `eventsForCategory()`, `eventsForTag()`, `exportAsJson()`
- **`TimestampProvider.fake()`** — deterministic timestamps for snapshot testing
- **Bounded capacity** — configurable FIFO eviction to prevent OOM in long-running tests

## Quick Start

```dart
import 'package:purple_logger/purple_logger.dart';

void main() {
  // One-liner
  final log = PurpleLogger.quick();
  log.info('Application started');

  // Full setup
  final factory = LoggingBuilder()
    .addConsole()
    .addFile('/var/log/app.log')
    .setMinimumLevel(PurpleLogLevel.info)
    .addFilterRule(FilterRule(
      categoryPrefix: 'network',
      minimumLevel: PurpleLogLevel.error,
    ))
    .enrichWith({'environment': 'production', 'appVersion': '2.1.0'})
    .build();

  final logger = factory.createLogger('OrderService');
  logger.info('Order placed', properties: {'orderId': 1042, 'total': 99.99});
  logger.error('Payment failed', properties: {'orderId': 1042}, error: PaymentException());

  factory.dispose();
}
```

## Environment Variable Config

```bash
export PLOG_LEVEL=info
export PLOG_FORMAT=json
export PLOG_OUTPUT=both
export PLOG_FILE_PATH=/var/log/app.log
```

```dart
final factory = LoggingBuilder.fromEnvironment().build();
```

## Enriched Logging

```dart
final factory = LoggingBuilder()
  .addConsole()
  .enrichWithEnricher(LoggerEnricher.fromEnvironment(
    appName: 'my-api',
    appVersion: '2.1.0',
    environment: 'production',
  ))
  .build();

// Every log event automatically includes:
//   hostname, pid, appName, appVersion, environment
```

## Filtering

```dart
final factory = LoggingBuilder()
  .addConsole()
  .addFile('/var/log/app.log')
  .setMinimumLevel(PurpleLogLevel.warning)           // global minimum
  .addFilterRule(FilterRule(                         // per-category
    categoryPrefix: 'network',
    minimumLevel: PurpleLogLevel.error,
  ))
  .addFilterRule(FilterRule(                         // per-provider
    providerType: FileLoggerProvider,
    minimumLevel: PurpleLogLevel.trace,
  ))
  .build();

// Runtime reconfiguration
factory.setMinimumLevel(PurpleLogLevel.debug);
factory.addFilterRule(FilterRule(
  categoryPrefix: 'auth',
  minimumLevel: PurpleLogLevel.trace,
));
```

## Zone-based Scopes

```dart
final logger = factory.createLogger('handler');
logger.info('Request started');

LoggingScope.run({'requestId': 'abc-123'}, () {
  logger.info('Processing'); // automatically includes requestId

  LoggingScope.run({'userId': '42'}, () {
    // Child scope merges: {requestId: abc-123, userId: 42}
    logger.info('User found');
  });
});
```

## File Logger with Rotation

```dart
final factory = LoggingBuilder()
  .addProvider(FileLoggerProvider(
    filePath: '/var/log/app.log',
    formatter: const JsonFormatter(),
    rotation: const RotatingFileConfig(
      maxFileSizeBytes: 50 * 1024 * 1024,  // 50 MB
      maxFiles: 10,
      compressRotated: true,
    ),
    flushIntervalMs: 500,
  ))
  .build();
```

## OpenTelemetry Integration

```dart
// purple_logger → PurpleOTel SDK → OTLP Collector
final factory = LoggingBuilder()
  .addConsole()
  .addProvider(PurpleOtelLoggerProvider(otelProvider: sdkLoggerProvider))
  .build();
```

## Testing

```dart
final store = MemoryLogStore(maxCapacity: 100);
final factory = LoggingBuilder()
  .addMemory(store: store)
  .setMinimumLevel(PurpleLogLevel.trace)
  .build();

final logger = factory.createLogger('test');
logger.info('test message', properties: {'key': 'value'});
logger.warning('warning');
logger.error('error');

// Query
final errors = store.eventsAtOrAbove(PurpleLogLevel.error);
final forCategory = store.eventsForCategory('test');
final json = store.exportAsJson();

store.clear();
```

## Architecture

```
User Code
    │
    ├─ logger.info("msg", {props})
    ▼
LoggerImpl.log()
    │ 1. isEnabled() zero-alloc guard
    │ 2. Single LogEvent allocation, shared across all providers
    │ 3. Merge scopeProperties + enricher properties
    │ 4. Dispatch to each ProviderLogger
    ▼
┌──────────────────┬─────────────────┬───────────────────┐
│ ConsoleLogger    │ FileLogger       │ MemoryLogger       │
│ (ANSI stdout)    │ (rotation)       │ (in-memory store)  │
│ SimpleFormatter  │ JsonFormatter    │ query API          │
└──────────────────┴─────────────────┴───────────────────┘
```

## Companion Packages

| Package | Description |
|---------|-------------|
| [purple_logger_otel](https://pub.dev/packages/purple_logger_otel) | OTel bridge abstractions |
| [purple_logger_otel_sdk](https://pub.dev/packages/purple_logger_otel_sdk) | PurpleOTel SDK bridge (our implementation) |
| [purple_otel_sdk](https://pub.dev/packages/purple_otel_sdk) | Full OpenTelemetry SDK |

---



## Enterprise Support

This package is developed and maintained by **[PurpleSoft S.r.l.](https://www.purplesoft.io)** — a software house based in Monza, Milano, and Lugano (Switzerland). Since 2017, we've been building the kind of software that other companies call "impossible."

We write the code that runs on factory floors and in boardrooms. We ship Flutter apps that control physical payment terminals, deploy ONNX models to mobile devices that fit in your pocket, and build distributed tracing pipelines that survive Black Friday traffic without dropping a single span. We've migrated ERP systems for multinational manufacturers, trained speech models that understand Italian dialects, and designed caching layers that make API latency disappear.

When a Flutter plugin doesn't exist for the hardware you need, we write it. When your OpenTelemetry collector falls over under load, we fix it. When your AI model needs to run on a phone instead of a server, we make it fit.

Our team spans the full stack — from bare-metal native code to cloud-native infrastructure, from machine learning pipelines to pixel-perfect UI. We don't specialize in one thing. We specialize in solving things that don't have an existing solution.

Trusted by **ABB, Intesa Sanpaolo, Tenaris, Reply, Aubay, Prometeia, Comune di Milano, FIMAP, Altran, BCC,** and 50+ other enterprises across Europe.

[Contact PurpleSoft](https://www.purplesoft.io/cerchi-contatti-software-house-a-monza-e-milano/) · [purplesoft.io](https://www.purplesoft.io) · [developers@purplesoft.io](mailto:developers@purplesoft.io) · [+39 0362 148 3978](tel:+3903621483978)## License

AGPL-3.0 — see [LICENSE](LICENSE).



