# purple_logger

Enterprise-grade structured logger for PurpleSoft Flutter plugins.

## Features

- **Zero `print()` calls** — all output goes through `package:logging`
- **Hierarchical named loggers** — `PurpleTTS`, `PurpleTTS.Engine`, etc.
- **Production-safe defaults** — WARNING+ in release, ALL in debug
- **Structured formatting** — `[LEVEL] [TIME] LoggerName: Message`
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