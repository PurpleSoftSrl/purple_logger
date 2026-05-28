import '../abstractions/logger.dart';
import '../abstractions/log_level.dart';

/// Extension that adds structured exception logging to [Logger].
///
/// Automatically derives `errorType` and `errorMessage` properties from the
/// error object, reducing boilerplate in catch blocks.
///
/// ```dart
/// try {
///   await fetchOrder(id);
/// } catch (e, st) {
///   logger.logException(e, st, message: 'Failed to fetch order', properties: {'orderId': id});
/// }
/// ```
extension LoggerExceptionExtension on Logger {
  /// Logs [error] with auto-derived `errorType` and `errorMessage` properties.
  ///
  /// When [message] is omitted, it is derived automatically from the error:
  /// - If `error.toString()` already starts with the type name, it is used as-is.
  /// - Otherwise the message becomes `"TypeName: error.toString()"`.
  void logException(
    Object error,
    StackTrace stackTrace, {
    PurpleLogLevel level = PurpleLogLevel.error,
    String? message,
    Map<String, Object?>? properties,
  }) {
    final autoMessage = message ?? _deriveMessage(error);
    final merged = <String, Object?>{
      'errorType': error.runtimeType.toString(),
      'errorMessage': error.toString(),
    };
    if (properties != null) merged.addAll(properties);
    log(
      level,
      autoMessage,
      properties: merged,
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _deriveMessage(Object error) {
    final str = error.toString();
    final typeName = error.runtimeType.toString();
    if (str.startsWith(typeName)) return str;
    return '$typeName: $str';
  }
}
