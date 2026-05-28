import '../abstractions/log_level.dart';
import '../abstractions/logger.dart';
import '../abstractions/logger_factory.dart';
import '../abstractions/logger_provider.dart';
import '../utils/timestamp_provider.dart';
import 'filter_rules.dart';
import 'logger_enricher.dart';
import 'logger_impl.dart';

final class LoggerFactoryImpl implements LoggerFactory {
  final List<LoggerProvider> _providers;
  FilterRuleSet _filters;
  final TimestampProvider _clock;
  final LoggerEnricher? _enricher;
  final Map<String, Logger> _cache = {};
  bool _disposed = false;

  LoggerFactoryImpl({
    required List<LoggerProvider> providers,
    required FilterRuleSet filters,
    required TimestampProvider clock,
    LoggerEnricher? enricher,
  })  : _providers = List.of(providers),
        _filters = filters,
        _clock = clock,
        _enricher = enricher;

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

  @override
  void addProvider(LoggerProvider provider) {
    _checkDisposed();
    _providers.add(provider);
    _cache.clear();
  }

  @override
  void setMinimumLevel(PurpleLogLevel level) {
    _filters = FilterRuleSet(
      rules: _filters.rules,
      globalMinimum: level,
    );
    _cache.clear();
  }

  @override
  void setGlobalLevel(PurpleLogLevel level) {
    setMinimumLevel(level);
  }

  @override
  void addFilterRule(FilterRule rule) {
    final newRules = List<FilterRule>.from(_filters.rules)..add(rule);
    _filters = FilterRuleSet(
      rules: newRules,
      globalMinimum: _filters.globalMinimum,
    );
    _cache.clear();
  }

  @override
  void removeFilterRule(FilterRule rule) {
    final newRules = _filters.rules.where((r) => r != rule).toList();
    _filters = FilterRuleSet(
      rules: newRules,
      globalMinimum: _filters.globalMinimum,
    );
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
