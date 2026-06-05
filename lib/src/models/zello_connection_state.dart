/// High-level connection lifecycle. Mirrors transitions reported by the
/// native SDK so the UI can render a simple badge.
enum ZelloConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed;

  static ZelloConnectionState fromWire(String? raw) {
    switch (raw) {
      case 'connecting':
        return ZelloConnectionState.connecting;
      case 'connected':
        return ZelloConnectionState.connected;
      case 'reconnecting':
        return ZelloConnectionState.reconnecting;
      case 'failed':
        return ZelloConnectionState.failed;
      case 'disconnected':
      default:
        return ZelloConnectionState.disconnected;
    }
  }
}
