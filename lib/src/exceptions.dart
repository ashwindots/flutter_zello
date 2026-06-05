/// Typed exception surfaced for every native-side failure.
///
/// The [code] mirrors the platform-channel error code emitted by the
/// Android/iOS sides (e.g. `not_connected`, `permission_denied`,
/// `network_error`). [message] is human-readable; [details] is optional
/// platform-specific payload.
class ZelloException implements Exception {
  final String code;
  final String message;
  final Object? details;

  const ZelloException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ZelloException($code): $message';
}
