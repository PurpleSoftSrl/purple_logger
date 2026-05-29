import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_factory.dart';
import '../abstractions/logger_provider.dart';
import '../utils/timestamp_provider.dart';
import 'filter_rules.dart';
import 'logger_enricher.dart';
import 'logger_impl.dart';

/// Default implementation of [LoggerFactory] that manages providers, filters,
/// and logger caching.
///
/// Loggers are cached by category and invalidated when providers, filters,
/// or the minimum level change.
final class LoggerFactoryImpl implements LoggerFactory {
  final List<LoggerProvider> _providers;
  FilterRuleSet _filters;
  final TimestampProvider _clock;
  final LoggerEnricher? _enricher;
  final Map<String, Logger> _cache = {};
  bool _disposed = false;

  /// Creates a [LoggerFactoryImpl].
  LoggerFactoryImpl({
    required List<LoggerProvider> providers,
    required FilterRuleSet filters,
    required TimestampProvider clock,
    LoggerEnricher? enricher,
  })  : _providers = List.of(providers),
        _filters = filters,
        _clock = clock,
        _enricher = enricher;

  /// Creates or returns a cached [Logger] for the given [category].
  ///
  /// Throws [StateError] if the factory has been [dispose]d.
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
        enricher: _enricher,
      );
    });
  }

  /// Registers a new [LoggerProvider] and invalidates the logger cache.
  ///
  /// Newly created loggers will include the new provider.
  @override
  void addProvider(LoggerProvider provider) {
    _checkDisposed();
    _providers.add(provider);
    _cache.clear();
  }

  /// Sets the global minimum [PurpleLogLevel] and invalidates the logger cache.
  @override
  void setMinimumLevel(PurpleLogLevel level) {
    _filters = FilterRuleSet(
      rules: _filters.rules,
      globalMinimum: level,
    );
    _cache.clear();
  }

  /// Alias for [setMinimumLevel].
  @override
  void setGlobalLevel(PurpleLogLevel level) {
    setMinimumLevel(level);
  }

  /// Adds a [FilterRule] and invalidates the logger cache.
  @override
  void addFilterRule(FilterRule rule) {
    final newRules = List<FilterRule>.from(_filters.rules)..add(rule);
    _filters = FilterRuleSet(
      rules: newRules,
      globalMinimum: _filters.globalMinimum,
    );
    _cache.clear();
  }

  /// Removes a [FilterRule] and invalidates the logger cache.
  @override
  void removeFilterRule(FilterRule rule) {
    final newRules = _filters.rules.where((r) => r != rule).toList();
    _filters = FilterRuleSet(
      rules: newRules,
      globalMinimum: _filters.globalMinimum,
    );
    _cache.clear();
  }

  /// Disposes all registered providers and clears the logger cache.
  ///
  /// Subsequent calls to any method except [dispose] will throw [StateError].
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
