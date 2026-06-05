# Changelog

## 0.1.0

- Initial scaffold of the `zello` Flutter plugin.
- Dart API: `Zello.initialize`, `connect`, `disconnect`, `startTalking`,
  `stopTalking`, `sendTextMessage`, `setStatus`, `getChannelState`, `events`
  stream, `connectionState` `ValueListenable`.
- Sealed `ZelloEvent` hierarchy + `ZelloEventCodec` for native -> Dart decoding.
- Android (Kotlin) `FlutterPlugin` + `MethodCallHandler` +
  `EventChannel.StreamHandler` + foreground service (`microphone` type) for
  background PTT.
- iOS (Swift) `FlutterPlugin` with AVAudioSession configuration and optional
  Apple PushToTalk (`PTChannelManager`) integration.
- Example app with connect form, big PTT button, live event log and
  connection-state badge.
- Unit tests for Dart method-channel layer and event codec.
- All native Zello SDK calls isolated in `ZelloSdkAdapter` on both platforms
  with `// TODO: confirm against Zello SDK vX` markers for SDK-version drift.
