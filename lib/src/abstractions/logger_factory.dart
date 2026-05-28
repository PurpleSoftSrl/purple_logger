import '../abstractions/log_level.dart';
import '../abstractions/logger_provider.dart';
import '../core/filter_rules.dart';
import 'logger.dart';

abstract interface class LoggerFactory {
  Logger createLogger(String category);
  void addProvider(LoggerProvider provider);
  void dispose();

  void setMinimumLevel(PurpleLogLevel level);

  void setGlobalLevel(PurpleLogLevel level);

  void addFilterRule(FilterRule rule);

  void removeFilterRule(FilterRule rule);
}
