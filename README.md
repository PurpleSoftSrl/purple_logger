# purple_logger

Enterprise-grade structured logger for Dart and Flutter.

Named after Argus Panoptes — the all-seeing guardian of Greek mythology.
Every event, every error, every trace — nothing escapes PurpleLogger.

## Features

- **Provider pipeline** — Multiple sinks (Console, Debug, Memory, Null, Custom) running simultaneously
- **Structured properties** — Key-value pairs kept separate from messages
- **Zone-based scopes** — Async-safe contextual properties that propagate through the entire call chain
- **Filter rules** — Global + per-category + per-provider level control
- **Zero-alloc guards** — `isEnabled()` exits before any object allocation
- **Formatters** — Simple (human-readable) and JSON out of the box
- **MemoryLogStore** — In-memory store with rich query methods for testing
- **Tag-based logging** — Lightweight secondary classification
- **Exception helper** — Auto-derived `errorType`/`errorMessage` properties
- **HTTP interceptor** — Framework-agnostic request/response/error logging
- **OpenTelemetry bridge** — Via the `purple_logger_otel` companion package
- **No dependencies** — Pure Dart; works on all platforms (CLI, Flutter, server, web)

## Quick start

### One-liner

```dart
import 'package:purple_logger/purple_logger.dart';

void main() {
  final log = PurpleLogger.quick();
  log.info('Application started');
  log.warning('Config file not found');
  log.error('Unexpected failure', error: exception, stackTrace: st);
  PurpleLogger.disposeQuickFactory();
}
```

### Full setup

```dart
import 'package:purple_logger/purple_logger.dart';

void main() {
  final factory = LoggingBuilder()
    .addConsole()
    .setMinimumLevel(PurpleLogLevel.info)
    .build();

  final logger = factory.createLogger('MyApp');
  logger.info('Application started');
  logger.info('User logged in', properties: {'userId': 42, 'role': 'admin'});
  logger.warning('Disk space low', properties: {'freeGb': 1.2});
  logger.error('Unexpected failure', error: exception, stackTrace: st);

  factory.dispose();
}
```

## Architecture

```
LoggingBuilder → LoggerFactory → Logger
                                     │
                   ┌─────────────────┼──────────────────┐
                   │                  │                  │
             ConsoleProvider    DebugProvider     MemoryProvider
                   │                  │                  │
             SimpleFormatter    dart:developer     MemoryLogStore
             (or JsonFormatter)  log()             (query/export)
```

## Log levels

| Level | Label | OTel SeverityNumber | Use case |
|-------|-------|--------------------:|----------|
| trace | TRCE | 1 | Method entry/exit, internal state |
| debug | DBUG | 5 | Developer diagnostics |
| info | INFO | 9 | Normal operational milestones |
| warning | WARN | 13 | Recoverable, unexpected situations |
| error | EROR | 17 | Failures requiring attention |
| fatal | CRIT | 21 | Unrecoverable failures |
| none | NONE | 0 | Sentinel — suppresses all output |

## Structured properties

Properties are kept separate from the message so every provider can decide
whether to render them inline (text) or persist them as structured fields (JSON):

```dart
logger.info('Order placed', properties: {'orderId': 1042, 'amount': 299.99});
```

## Scoped logging

Scopes carry contextual properties through an entire async call chain via
Dart's `Zone` mechanism — no manual threading required:

```dart
final scope = logger.beginScope({'requestId': request.id, 'userId': request.userId});
await scope.runAsync(() async {
  logger.info('Processing');   // includes requestId + userId
  await callDownstream();
  logger.info('Done');         // still includes requestId + userId
});
```

## Filter rules

```dart
final factory = LoggingBuilder()
  .addConsole()
  .setMinimumLevel(PurpleLogLevel.debug)                // global floor
  .addFilterRule(FilterRule(
    categoryPrefix: 'network',
    minimumLevel: PurpleLogLevel.error,                  // noisy subsystem override
  ))
  .addFilterRule(FilterRule(
    providerType: ConsoleLoggerProvider,
    categoryPrefix: 'metrics',
    minimumLevel: PurpleLogLevel.none,                  // silence metrics on console
  ))
  .build();
```

Rule specificity (highest wins):
1. Provider type and category prefix
2. Category prefix only
3. Provider type only
4. Global minimum (catch-all)

## Providers

### Console (`ConsoleLoggerProvider`)

Writes ANSI-colored output to `stdout`. Available on all platforms except web.

```dart
LoggingBuilder().addConsole()
LoggingBuilder().addConsole(formatter: const JsonFormatter())
```

### Debug (`DebugLoggerProvider`)

Writes to `dart:developer`'s `log()`, visible in Flutter/Dart DevTools. Works on all platforms including web.

```dart
LoggingBuilder().addDebug()
```

### Memory (`MemoryLoggerProvider` + `MemoryLogStore`)

Stores events in memory; primarily intended for unit and integration tests.

```dart
final store = MemoryLogStore();
final factory = LoggingBuilder()
  .addMemory(store: store)
  .setMinimumLevel(PurpleLogLevel.trace)
  .build();

// Query methods
store.events;
store.eventsAtOrAbove(PurpleLogLevel.warning);
store.eventsForCategory('OrderService');
store.eventsForTag('auth');
store.exportAsJson();
store.clear();
```

### Null (`NullLoggerProvider` / `NullLogger`)

Discards every entry. Useful as a no-op default for optional logger dependencies.

```dart
class MyService {
  MyService({Logger? logger}) : _logger = logger ?? NullLogger();
  final Logger _logger;
}
```

### Custom providers

```dart
final class SyslogProvider extends LoggerProvider {
  @override
  Logger createLogger(String category) => SyslogLogger(category: category);

  @override
  void dispose() { /* close socket */ }
}
```

## Tag-based logging

```dart
logger.infoTagged('auth', 'User signed in', properties: {'userId': 42});
logger.errorTagged('payment', 'Charge failed', error: ex, stackTrace: st);
```

## Exception helper

```dart
try {
  await fetchOrder(id);
} catch (e, st) {
  logger.logException(e, st, message: 'Failed to fetch order', properties: {'orderId': id});
  // Automatically adds: errorType, errorMessage to properties
}
```

## HTTP interceptor

Framework-agnostic — works with `dio`, `http`, or any HTTP client:

```dart
final interceptor = HttpLogInterceptor(logger, logHeaders: true);
interceptor.onRequest('GET', 'https://api.example.com/orders/1');
interceptor.onResponse(200, 'https://api.example.com/orders/1', durationMs: 42);
interceptor.onError('GET', 'https://api.example.com/orders/1', error, st);
```

## OpenTelemetry bridge

Use the `purple_logger_otel` companion package to bridge PurpleLogger events
to OpenTelemetry via OTLP (gRPC/HTTP):

```dart
import 'package:purple_logger_otel/purple_logger_otel.dart';

final factory = LoggingBuilder()
  .addProvider(OtelLoggerProvider(endpoint: 'http://otel-collector:4318'))
  .addConsole()
  .build();
```

## Performance

- **Zero allocations** when a log level is disabled — `isEnabled` exits before any object is created.
- **Single `LogEvent` allocation** per `log()` call, shared across all providers.
- **Zone-local scope lookup** — O(1) read, no contention.
- **No reflection** — category names are plain strings; no `dart:mirrors`.
- **Efficient ring buffer** in `MemoryLogStore` — O(1) eviction via `ListQueue`.

```dart
if (logger.isEnabled(PurpleLogLevel.debug)) {
  logger.debug('Snapshot: ${expensiveDump()}');
}
```

## License

Apache-2.0
- **Error + StackTrace support** — full context on failures
- **Lightweight** — depends only on `package:logging`

## Usage

```dart
import 'package:purple_logger/purple_logger.dart';

final _log = PurpleLogger('PurpleTTS');

_log.info('Engine initialized');
_log.warning('Voice not found, falling back');
_log.error('Synthesis failed', error: e, stackTrace: st);
```

## Log Levels

| Level     | Use Case                          |
|-----------|-----------------------------------|
| `finest`  | Verbose internal tracing          |
| `finer`   | Detailed tracing (event dispatch) |
| `fine`    | General tracing (state changes)   |
| `config`  | Configuration changes             |
| `info`    | Important operational events       |
| `warning` | Recoverable issues                 |
| `error`   | Failures requiring attention       |
| `critical`| Critical failures                  |