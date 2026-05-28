/// Injectable clock abstraction for deterministic testing.
///
/// Production code uses [TimestampProvider.utc] (real wall-clock).
/// Tests can inject [TimestampProvider.fake] for reproducible timestamps.
abstract class TimestampProvider {
  TimestampProvider._();

  /// Returns the current UTC time.
  DateTime now();

  /// Real wall-clock provider (production default).
  static TimestampProvider utc = _UtcTimestampProvider();

  /// Fake provider that returns a fixed [DateTime] for testing.
  static TimestampProvider fake(DateTime fixed) =>
      _FakeTimestampProvider(fixed);
}

final class _UtcTimestampProvider extends TimestampProvider {
  _UtcTimestampProvider() : super._();

  @override
  DateTime now() => DateTime.now().toUtc();
}

final class _FakeTimestampProvider extends TimestampProvider {
  final DateTime _fixed;
  _FakeTimestampProvider(this._fixed) : super._();

  @override
  DateTime now() => _fixed;
}
