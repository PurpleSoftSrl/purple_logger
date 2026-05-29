import '../abstractions/logger.dart';
import '../abstractions/log_level.dart';

/// Framework-agnostic HTTP logging interceptor.
///
/// Wire into any HTTP client's lifecycle without a direct dependency on
/// `dio`, `http`, or any other network package.
///
/// ```dart
/// final interceptor = HttpLogInterceptor(
///   logger,
///   requestLevel: PurpleLogLevel.debug,
///   responseLevel: PurpleLogLevel.debug,
///   errorLevel: PurpleLogLevel.error,
/// );
/// interceptor.onRequest('GET', 'https://api.example.com/orders/1');
/// interceptor.onResponse(200, 'https://api.example.com/orders/1', durationMs: 42);
/// interceptor.onError('GET', 'https://api.example.com/orders/1', error, st);
/// ```
final class HttpLogInterceptor {
  final Logger _logger;

  /// [PurpleLogLevel] for request logs. Defaults to [PurpleLogLevel.debug].
  final PurpleLogLevel requestLevel;

  /// [PurpleLogLevel] for response logs. Defaults to [PurpleLogLevel.debug].
  final PurpleLogLevel responseLevel;

  /// [PurpleLogLevel] for error logs. Defaults to [PurpleLogLevel.error].
  final PurpleLogLevel errorLevel;

  /// Whether to include HTTP headers in log properties.
  final bool logHeaders;

  /// Whether to include HTTP request/response body in log properties.
  final bool logBody;

  /// Creates an [HttpLogInterceptor] that writes to [_logger].
  const HttpLogInterceptor(
    this._logger, {
    this.requestLevel = PurpleLogLevel.debug,
    this.responseLevel = PurpleLogLevel.debug,
    this.errorLevel = PurpleLogLevel.error,
    this.logHeaders = false,
    this.logBody = false,
  });

  /// Call when an HTTP request is initiated.
  void onRequest(
    String method,
    String url, {
    Map<String, Object?>? headers,
    Object? body,
  }) {
    final props = <String, Object?>{
      'http.method': method,
      'http.url': url,
    };
    if (logHeaders && headers != null) props['http.request.headers'] = headers;
    if (logBody && body != null) props['http.request.body'] = body;
    _logger.log(requestLevel, '$method $url', properties: props);
  }

  /// Call when an HTTP response is received.
  void onResponse(
    int statusCode,
    String url, {
    int? durationMs,
    Map<String, Object?>? headers,
    Object? body,
  }) {
    final props = <String, Object?>{
      'http.status': statusCode,
      'http.url': url,
    };
    if (durationMs != null) props['http.durationMs'] = durationMs;
    if (logHeaders && headers != null) props['http.response.headers'] = headers;
    if (logBody && body != null) props['http.response.body'] = body;
    _logger.log(responseLevel, '$statusCode $url', properties: props);
  }

  /// Call when an HTTP request fails.
  void onError(
    String method,
    String url,
    Object error,
    StackTrace stackTrace, {
    int? statusCode,
    Map<String, Object?>? headers,
    Object? body,
  }) {
    final props = <String, Object?>{
      'http.method': method,
      'http.url': url,
    };
    if (statusCode != null) props['http.status'] = statusCode;
    if (logHeaders && headers != null) props['http.request.headers'] = headers;
    if (logBody && body != null) props['http.request.body'] = body;
    _logger.log(
      errorLevel,
      '$method $url failed',
      properties: props,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
