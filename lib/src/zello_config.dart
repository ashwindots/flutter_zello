import 'package:meta/meta.dart';

/// Plugin-wide configuration passed once on [Zello.initialize].
@immutable
class ZelloConfig {
  /// [appKey] / SDK key issued by Zello Work for your application.
  /// On Android this maps to the SDK consumer key; on iOS to the equivalent
  /// initializer parameter — see the native adapter for the exact symbol.
  final String appKey;

  /// Optional issuer to embed in default JWT claims. The plugin does not
  /// mint tokens — your backend does — but some SDK builds accept the
  /// issuer as a separate hint.
  final String? issuer;

  /// If `true`, the Android implementation will start a foreground service
  /// while connected so PTT and audio RX continue with the app backgrounded
  /// or the screen off. Strongly recommended for production.
  final bool enableForegroundService;

  /// If `true`, the iOS implementation registers a `PTChannelManager`
  /// (Apple PushToTalk framework) so the OS treats the app as a proper PTT
  /// app. Requires the `com.apple.developer.push-to-talk` entitlement.
  final bool enableApplePushToTalk;

  /// Optional human-readable label shown in the Android foreground-service
  /// notification and iOS PT channel descriptor.
  final String channelDisplayName;

  const ZelloConfig({
    required this.appKey,
    this.issuer,
    this.enableForegroundService = true,
    this.enableApplePushToTalk = true,
    this.channelDisplayName = 'Zello',
  });

  Map<String, Object?> toMap() => <String, Object?>{
        'appKey': appKey,
        'issuer': issuer,
        'enableForegroundService': enableForegroundService,
        'enableApplePushToTalk': enableApplePushToTalk,
        'channelDisplayName': channelDisplayName,
      };
}
