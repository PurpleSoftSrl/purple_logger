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

## Quality & Reliability

PurpleLogger is built to run in production — not just pass a quick demo. Every component is hardened against edge cases discovered through adversarial testing.

### By the Numbers

| Metric | Value |
|--------|-------|
| Total tests | **256** (95 SDK + 107 logger + 54 Flutter) |
| Test failures | **0** |
| Red team audit | **Passed** — 8 critical bugs found and fixed |
| NaN/Infinity safe | ✅ Rejected at aggregation layer |
| Config validation | ✅ Batch processors guard against zero/invalid values |
| LogEvent immutability | ✅ Events are immutable after dispatch |
| Error truncation | ✅ Messages limited to 256 characters |
| Cyclic data safe | ✅ hashCode and equality protected against cyclic maps |
| Disposed dependencies | ✅ All callbacks try-catch wrapped |

### Production Hardening

- **LogEvent immutability**: After a log event is dispatched to providers, it is shared read-only. No accidental mutations during formatting or export.
- **Severity guard**: `isEnabled()` zero-alloc check prevents object allocation when log level is below minimum. Zero-cost trace/debug logs in production.
- **Config validation**: `RotatingFileConfig` ensures `maxFileSizeBytes` and `maxFiles` are always positive. Zero crashes from misconfigured rotation.
- **Safe error handling**: If an exception's `toString()` method itself throws, the SDK catches it and records `<error>` instead of crashing.
- **Cyclic map protection**: If structured log properties contain self-referencing maps, `hashCode` computation uses try-catch fallback instead of `StackOverflowError`.
- **Double-initialization guard**: `LoggingBuilder.initialize()` can be called multiple times safely — only the first call takes effect.
- **Disposed logger safety**: All provider callbacks are wrapped in try-catch. A disposed logger never crashes the Flutter framework.
- **String interning**: Property keys are interned to minimize GC pressure in high-throughput scenarios.
- **Lazy allocation**: LogEvent property maps are only allocated when first used. Zero-cost log events in the common case.

---

## Companion Packages

| Package | Description |
|---------|-------------|
| [purple_logger_otel](https://pub.dev/packages/purple_logger_otel) | OTel bridge abstractions |
| [purple_logger_otel_sdk](https://pub.dev/packages/purple_logger_otel_sdk) | PurpleOTel SDK bridge (our implementation) |
| [purple_otel_sdk](https://pub.dev/packages/purple_otel_sdk) | Full OpenTelemetry SDK |

---

---

---

---


---

## Built by PurpleSoft

**[PurpleSoft S.r.l.](https://www.purplesoft.io)** — software house with offices in Monza, Milano, and Lugano (Switzerland). Since 2017.

> We build what doesn't exist yet.

### The sectors we dominate

**Conversational AI & Voice Assistants.** We design and ship end-to-end AI voice platforms — from the physical device (ESP32 with custom Opus codec firmware) to the cloud backend (.NET 10, ASP.NET Core, Blazor Server) to the mobile companion app (Flutter with BLE). Our multi-agent LLM architecture orchestrates 8 specialized agents (conversation, memory, content enrichment, exploration, and more) with a multi-layered memory system spanning graph, episodic, and working memory — including adaptive forgetting, poison detection via z-score outlier analysis, and automatic episodic-to-semantic compression. We deploy DeepSeek V4 for primary inference at 53x lower cost than GPT-4o, with multi-provider fallback across OpenAI, Anthropic, Gemini, and Ollama. Our scientific research pipeline uses a 4-scorer verification chain (NLI dual-label, cross-model consistency, evidence retrieval, hallucination detection) with consensus voting to ensure factual accuracy. We design RAG pipelines with HNSW vector search (1024-dim embeddings), hybrid full-text + semantic RRF, sharded K-means search, and training-free chunk pre-filtering.

**Fintech & Payments.** We build payment orchestration layers that abstract Stripe, SumUp, Nexi, Axerve, PayPal, Google Pay, and Apple Pay behind a single API — plus Bitcoin, Ethereum, and 100+ cryptocurrencies. Our engineers have shipped POS terminal firmware, fiscal receipt systems compliant with Italian *Fattura Elettronica* regulations, and cash register management platforms processing millions of transactions.

**Cybersecurity & Identity.** We ship post-quantum cryptography implementations using NIST-standardized algorithms on .NET 10 (ML-KEM, ML-DSA, SLH-DSA) — the cryptography standard that will replace RSA and ECC. Our authentication infrastructure integrates SPID (Italian public digital identity), OAuth 2.0/OpenID Connect across Google, Apple, Microsoft, Facebook, Instagram, LinkedIn, and GitHub. We build digital signature platforms with PKCS#11 hardware security module support, handling the full envelope lifecycle from document preparation to legally binding execution.

**Artificial Intelligence & On-Device ML.** We deploy ONNX models to phones via custom Dart runtime bindings with GPU acceleration. We integrate Litert and MediaPipe for on-device LLM inference. We build neural text-to-speech engines that run across all 6 Flutter platforms — from Android to Web — and speech recognition systems with Italian dialect support. We design content intelligence pipelines that ingest, enrich via LLM, embed (1024-dim vectors), and serve via hybrid semantic search — at scale: 28,000 items enriched, 30,000 embeddings generated, 14 pipelines with 3 stages each (scrape → enrich → embed). DeepSeek V4 Pro processes content enrichment at a fraction of the cost of GPT-4o.

**Enterprise SaaS & Cloud-Native Architecture.** We architect, build, and operate platforms at enterprise scale. Our .NET 10 monorepo spans 239 C# projects with consistent Azure Pipelines CI/CD, 297 test suites passing, zero build errors. We design multi-engine database abstraction layers (PostgreSQL + pgvector, MySQL, Microsoft SQL Server) with automated schema-to-code generation that produces complete ASP.NET API controllers. Our notification engine handles 6 channels (email, push, SMS, chat, webhook, in-app) with DNS-based email validation and template management. Our audio SDK provides unified TTS/STT across ElevenLabs, DashScope, DeepGram, Whisper, and Windows Speech with Opus/OGG codec support and real-time streaming.

**IoT & Embedded Systems.** We write ESP32 firmware targeting ESP-IDF v5.4 with 21 FreeRTOS tasks, I²S audio pipelines, Opus codec integration, and a 6-state WiFi state machine with validated recovery paths. We build certificate authority infrastructure that generates and manages device TLS certificates with challenge-response verification. We write native Flutter plugins for hardware that doesn't have one yet — from payment terminals to BLE device provisioning to audio codecs.

**Observability & DevOps.** Full-stack observability is the foundation we build our client solutions on. We ship a complete OpenTelemetry SDK for Dart/Flutter (traces, logs, metrics, W3C propagation, OTLP export), enterprise structured logging with file rotation, and auto-instrumentation for HTTP, Dio, and Flutter navigation — all red-team audited with 256 automated tests.

### The technologies we master

Our engineering team works across the full stack — from ESP32 firmware in C to cloud-native backends in C# (.NET 10) to cross-platform mobile apps in Dart/Flutter. We write production code in **C# (.NET 10)**, **Dart**, **TypeScript**, **JavaScript**, **C**, **C++**, **Python**, and **Rust**. Our frameworks of choice are **ASP.NET Core**, **Blazor Server**, **Flutter**, **Angular**, and **React**. Our AI stack spans **DeepSeek**, **OpenAI**, **Anthropic Claude**, **Google Gemini**, **Ollama**, **Microsoft Semantic Kernel**, and **Microsoft Agents.AI**. We operate **Microsoft Azure** (Key Vault, Blob Storage, Resource Manager, IoT Hub, Virtual Machines), deploy on **NGINX**, and manage **PostgreSQL + pgvector**, **MySQL**, **Microsoft SQL Server**, and **ESP-IDF v5.4** at scale. We use **EF Core** with **Npgsql** for data access, **FFmpeg** for audio processing, **LVGL** for embedded displays, and **BLE** for device provisioning. Our CI/CD runs on **Azure Pipelines**.

### Microsoft Partner since 2018 · SumUp Partner · Dell Partner

---

### Trusted by

`ABB` `Intesa Sanpaolo` `Tenaris` `Reply` `Aubay` `Comune di Milano` `BCC` `FIMAP` `Alten` `Altran` `Prometeia` `illimity` `Be Shaping the Future` `DS Group` `NVALUE` `Inoptim` `Docflow` `P&C`

*and 40+ other enterprises across banking, manufacturing, energy, and public sector.*

---

> Your project can't wait. We've solved these exact problems for companies you know.
> Let's solve them for you.

[🌐 **purplesoft.io**](https://www.purplesoft.io) &nbsp;·&nbsp; [📧 **developers@purplesoft.io**](mailto:developers@purplesoft.io) &nbsp;·&nbsp; [📞 **+39 0362 148 3978**](tel:+3903621483978) &nbsp;·&nbsp; [💼 **LinkedIn**](https://www.linkedin.com/company/purplesoft-srl) &nbsp;·&nbsp; [🐙 **GitHub**](https://github.com/purplesoftsrl)

## License

AGPL-3.0 — see [LICENSE](LICENSE).











