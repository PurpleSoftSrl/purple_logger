import '../abstractions/log_level.dart';

/// A single filtering rule that maps a provider type and/or category prefix
/// to a minimum [PurpleLogLevel].
///
/// Rules are evaluated in order of specificity (most specific wins):
/// 1. Provider type **and** category prefix
/// 2. Category prefix only
/// 3. Provider type only
/// 4. Global minimum (catch-all)
final class FilterRule {
  /// Minimum level for this rule.
  final PurpleLogLevel minimumLevel;

  /// Category prefix to match (e.g. `'network'` matches `'network.http'`).
  final String? categoryPrefix;

  /// Provider runtime type to match.
  final Type? providerType;

  const FilterRule({
    required this.minimumLevel,
    this.categoryPrefix,
    this.providerType,
  });

  /// Specificity score: higher = more specific.
  int get specificity =>
      (providerType != null ? 2 : 0) + (categoryPrefix != null ? 1 : 0);

  /// Returns `true` if this rule matches [providerType] and [category].
  bool matches(Type providerType, String category) {
    if (this.providerType != null && this.providerType != providerType) {
      return false;
    }
    if (categoryPrefix != null && !category.startsWith(categoryPrefix!)) {
      return false;
    }
    return true;
  }
}

/// Ordered set of [FilterRule]s that determines the effective minimum
/// [PurpleLogLevel] for each provider/category combination.
///
/// Rules are sorted by specificity (most specific first). When multiple
/// rules match, the first (most specific) wins. If no rule matches, the
/// [globalMinimum] applies.
final class FilterRuleSet {
  final List<FilterRule> _rules;
  final PurpleLogLevel _globalMinimum;

  /// Creates a [FilterRuleSet] with optional [rules] and a [globalMinimum].
  ///
  /// Rules are automatically sorted by descending specificity.
  FilterRuleSet({
    List<FilterRule>? rules,
    PurpleLogLevel globalMinimum = PurpleLogLevel.trace,
  })  : _rules = rules != null ? List.of(rules) : [],
        _globalMinimum = globalMinimum {
    _rules.sort((a, b) => b.specificity.compareTo(a.specificity));
  }

  /// All rules in this set (unmodifiable).
  List<FilterRule> get rules => List.unmodifiable(_rules);

  /// The fallback level when no rule matches.
  PurpleLogLevel get globalMinimum => _globalMinimum;

  /// Returns the effective minimum level for [providerType] and [category].
  ///
  /// Walks rules in specificity order; the first match wins.
  PurpleLogLevel getEffectiveLevel(Type providerType, String category) {
    for (final rule in _rules) {
      if (rule.matches(providerType, category)) {
        return rule.minimumLevel;
      }
    }
    return _globalMinimum;
  }

  /// Returns `true` if [level] passes the filter for [providerType]/[category].
  ///
  /// [PurpleLogLevel.none] always returns `false`.
  bool isEnabled(Type providerType, String category, PurpleLogLevel level) {
    if (level.isNone) return false;
    final minimum = getEffectiveLevel(providerType, category);
    return level.isAtLeast(minimum);
  }
}
