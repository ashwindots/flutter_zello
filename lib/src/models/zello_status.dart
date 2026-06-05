/// User presence/status reported to Zello.
enum ZelloStatus {
  available('available'),
  busy('busy'),
  standby('standby'),
  away('away');

  final String wireName;
  const ZelloStatus(this.wireName);

  /// Decode the on-wire string sent from native. Falls back to [available]
  /// for unknown values so a future native status never crashes Dart.
  static ZelloStatus fromWire(String? raw) {
    for (final s in ZelloStatus.values) {
      if (s.wireName == raw) return s;
    }
    return ZelloStatus.available;
  }
}
