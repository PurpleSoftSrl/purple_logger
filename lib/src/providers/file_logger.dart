import 'dart:async';
import 'dart:io';

import '../abstractions/event_logger.dart';
import '../abstractions/log_event.dart';
import '../abstractions/log_formatter.dart';
import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_provider.dart';
import '../abstractions/logging_scope.dart';
import '../formatting/simple_formatter.dart';

/// Configuration for automatic log file rotation.
///
/// When the log file exceeds [maxFileSizeBytes], it is rotated:
/// `app.log` → `app.log.1` → `app.log.2` … up to [maxFiles].
/// Optionally compresses rotated files with GZip when [compressRotated] is `true`.
final class RotatingFileConfig {
  /// Maximum file size in bytes before rotation. Defaults to 10 MiB.
  final int maxFileSizeBytes;

  /// Maximum number of rotated files to retain. Defaults to 5.
  final int maxFiles;

  /// If `true`, rotated files are GZip-compressed. Defaults to `false`.
  final bool compressRotated;

  const RotatingFileConfig({
    this.maxFileSizeBytes = 10 * 1024 * 1024,
    this.maxFiles = 5,
    this.compressRotated = false,
  });
}

/// [LoggerProvider] that writes formatted log events to a file on disk.
///
/// Supports periodic flushing, automatic rotation via [RotatingFileConfig],
/// and any [LogFormatter]. Default formatter is [SimpleFormatter] with
/// timestamps.
///
/// ```dart
/// LoggingBuilder().addFile(filePath: 'logs/app.log');
/// LoggingBuilder().addFile(
///   filePath: 'logs/app.log',
///   rotation: const RotatingFileConfig(maxFileSizeBytes: 5 * 1024 * 1024),
/// );
/// ```
final class FileLoggerProvider extends LoggerProvider {
  final String _filePath;
  final LogFormatter _formatter;
  final RotatingFileConfig _rotation;
  final List<LogEvent> _buffer = [];
  final List<FileLogger> _loggers = [];
  RandomAccessFile? _file;
  Timer? _flushTimer;
  int _currentFileSize = 0;
  bool _disposed = false;

  /// Creates a [FileLoggerProvider].
  ///
  /// [filePath] is the path to the log file. Parent directories are created
  /// automatically. [flushIntervalMs] controls how often the buffer is
  /// flushed to disk (0 disables periodic flushing).
  FileLoggerProvider({
    required String filePath,
    LogFormatter? formatter,
    RotatingFileConfig? rotation,
    int flushIntervalMs = 500,
  })  : _filePath = filePath,
        _formatter = formatter ?? const SimpleFormatter(includeTimestamp: true),
        _rotation = rotation ?? const RotatingFileConfig() {
    _ensureDirectoryExists();
    _openFile();
    if (flushIntervalMs > 0) {
      _flushTimer = Timer.periodic(
        Duration(milliseconds: flushIntervalMs),
        (_) => _flush(),
      );
    }
  }

  /// Creates the parent directory if it doesn't exist.
  void _ensureDirectoryExists() {
    final dir = Directory(File(_filePath).parent.path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  void _openFile() {
    final f = File(_filePath);
    if (f.existsSync()) {
      _currentFileSize = f.lengthSync();
    }
    _file = f.openSync(mode: FileMode.append);
  }

  /// Creates a new [FileLogger] for the given [category].
  @override
  Logger createLogger(String category) {
    final logger = FileLogger(
      category: category,
      provider: this,
    );
    _loggers.add(logger);
    return logger;
  }

  void _write(LogEvent event) {
    if (_disposed) return;
    final line = _formatter.format(event);
    _buffer.add(event);
    _currentFileSize += line.length + 1;
    if (_currentFileSize >= _rotation.maxFileSizeBytes) {
      _rotate();
    }
  }

  void _flush() {
    if (_disposed || _buffer.isEmpty) return;
    final lines = _buffer.map((e) => _formatter.format(e)).toList();
    final output = '${lines.join('\n')}\n';
    _file?.writeStringSync(output);
    _file?.flushSync();
    _buffer.clear();
  }

  void _rotate() {
    _flush();
    _file?.closeSync();
    for (var i = _rotation.maxFiles - 1; i >= 0; i--) {
      final oldName = i == 0 ? _filePath : '$_filePath.$i';
      final newName = '$_filePath.${i + 1}';
      final oldFile = File(oldName);
      if (oldFile.existsSync()) {
        final newFile = File(newName);
        if (newFile.existsSync()) newFile.deleteSync();
        oldFile.renameSync(newName);
        if (_rotation.compressRotated) {
          _compressFile(File(newName));
        }
      }
    }
    _currentFileSize = 0;
    _openFile();
  }

  static void _compressFile(File file) {
    final bytes = file.readAsBytesSync();
    final compressed = gzip.encode(bytes);
    final gzFile = File('${file.path}.gz');
    gzFile.writeAsBytesSync(compressed);
    file.deleteSync();
  }

  /// Flushes any pending writes, cancels the flush timer, closes the file,
  /// and clears registered loggers.
  @override
  void dispose() {
    _disposed = true;
    _flushTimer?.cancel();
    _flush();
    _file?.closeSync();
    _loggers.clear();
  }
}

/// [EventLogger] that buffers formatted lines and writes them to the
/// owning [FileLoggerProvider]'s file output.
final class FileLogger with LoggerConvenience implements EventLogger {
  /// Logger category name.
  @override
  final String category;

  /// Back-reference to the owning provider.
  final FileLoggerProvider _provider;

  FileLogger({required this.category, required FileLoggerProvider provider})
      : _provider = provider;

  /// Always enabled unless [PurpleLogLevel.none].
  @override
  bool isEnabled(PurpleLogLevel level) => !level.isNone;

  /// Buffers [event] for batch writing by the owning [FileLoggerProvider].
  @override
  void write(LogEvent event) => _provider._write(event);

  /// No-op — dispatching is handled by [LoggerImpl].
  @override
  void log(
    PurpleLogLevel level,
    Object? message, {
    Map<String, Object?>? properties,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  /// Creates a new [LoggingScope] with the given [properties].
  @override
  LoggingScope beginScope(Map<String, Object?> properties) =>
      LoggingScope(properties);
}
