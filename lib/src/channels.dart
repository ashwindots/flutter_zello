/// Channel names shared between Dart and native sides. Keep in sync with
/// `ZelloPlugin.kt` (Android) and `ZelloPlugin.swift` (iOS).
class ZelloChannels {
  ZelloChannels._();

  static const String method = 'com.zello.flutter/method';
  static const String events = 'com.zello.flutter/events';
}
