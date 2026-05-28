import '../abstractions/logger.dart';
import '../abstractions/logger_factory.dart';
import '../abstractions/logger_provider.dart';
import '../utils/timestamp_provider.dart';
import 'filter_rules.dart';
import 'logger_impl.dart';

/// Concrete [LoggerFactory] that manages the provider pipeline.
final class LoggerFactoryImpl implements LoggerFactory {
  final List<LoggerProvider> _providers;
  final FilterRuleSet _filters;
  final TimestampProvider _clock;
  final Map<String, Logger> _cache = {};
  bool _disposed = false;

  LoggerFactoryImpl({
    required List<LoggerProvider> providers,
    required FilterRuleSet filters,
    required TimestampProvider clock,
  })  : _providers = List.of(providers),
        _filters = filters,
        _clock = clock;

  @override
  Logger createLogger(String category) {
    _checkDisposed();
    return _cache.putIfAbsent(category, () {
      final providerLoggers = _providers
          .map((p) => ProviderLogger(p.createLogger(category), p.runtimeType))
          .toList();
      return LoggerImpl(
        category: category,
        providerLoggers: providerLoggers,
        filters: _filters,
        clock: _clock,
      );
    });
  }

  @override
  void addProvider(LoggerProvider provider) {
    _checkDisposed();
    _providers.add(provider);
    // Invalidate cache — new provider needs fresh loggers.
    _cache.clear();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final p in _providers) {
      p.dispose();
    }
    _cache.clear();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('LoggerFactory has been disposed');
    }
  }
}