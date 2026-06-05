# zello — Flutter plugin for the Zello Work Mobile SDKs

A Flutter plugin that wraps the **native Zello Work Mobile SDKs**
(Android Kotlin, iOS Swift) and exposes a clean, idiomatic Dart API for:

- Push-to-talk (works with the screen off / app in background)
- Channel connect / disconnect with auto-reconnect events
- Voice TX (start/stopTalking) and RX (incoming voice start/stop events)
- Text messages
- Presence / status
- Hardware PTT buttons and Apple PushToTalk integration on iOS

There is **no official Zello Flutter SDK** — this package is a community
platform-channel wrapper around the official native SDKs.

## Installation

```yaml
dependencies:
  zello: ^0.1.0
```

```dart
import 'package:zello/zello.dart';
```

## Quick start

```dart
await Zello.instance.initialize(
  config: const ZelloConfig(appKey: '<your-zello-sdk-key>'),
);

final sub = Zello.instance.events.listen((event) {
  // event is a sealed ZelloEvent – switch on its subtypes
});

await Zello.instance.connect(
  network: 'mycompany.zellowork.com',
  token: jwtFromYourBackend, // RS256, short-lived
);

// PTT button pressed
await Zello.instance.startTalking('dispatch');
// PTT button released
await Zello.instance.stopTalking();
```

## Public Dart API

| Member | Purpose |
|---|---|
| `Zello.initialize({required ZelloConfig config})` | One-time native init. |
| `connect({required String network, required String token, String? username})` | Connect to a Zello Work network with a short-lived JWT. |
| `disconnect()` | Disconnect. Idempotent. |
| `startTalking(String channel)` | Begin TX. Wire to PTT press. |
| `stopTalking()` | End TX. Wire to PTT release. |
| `sendTextMessage(String channel, String text)` | Send a text message. |
| `setStatus(ZelloStatus status)` | Update presence. |
| `getChannelState(String channel)` → `ZelloChannel` | Snapshot of a channel. |
| `events` | `Stream<ZelloEvent>` (broadcast). |
| `connectionState` | `ValueListenable<ZelloConnectionState>` for UI. |
| `dispose()` | Tear down native resources. |

All native failures surface as `ZelloException(code, message, details)`.
Events are a sealed Dart-3 hierarchy — `switch` exhaustively over
`ZelloConnectionStateChanged`, `ZelloIncomingVoiceStarted/Stopped`,
`ZelloOutgoingTalkStateChanged`, `ZelloIncomingTextMessage`,
`ZelloChannelStatusChanged`, `ZelloReconnectAttempt`, `ZelloErrorEvent`,
`ZelloUnknownEvent`.

## Setup & Native SDK Installation

The Zello Mobile SDKs are **gated behind a Zello Work subscription** and
cannot be redistributed via this repo. You must obtain them yourself and
wire them in.

### 1. Obtain the SDK artifacts

1. Sign in to your Zello Work admin portal.
2. Provision an **SDK key** for your app.
3. Download:
   - **Android**: AAR or Maven coordinates of the Zello Channels SDK.
   - **iOS**: XCFramework (or CocoaPods coordinate, if your subscription
     ships one).

### 2. Android wiring

In `android/build.gradle.kts` of this plugin (already scaffolded):

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.zello.com/release") } // example
    }
}

dependencies {
    implementation("com.zello:zello-channel-sdk:<version>")
    // or, for a local AAR:
    // implementation(files("libs/zello-channel-sdk.aar"))
}
```

The plugin already declares (in `android/src/main/AndroidManifest.xml`):

- `RECORD_AUDIO`
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`
- `POST_NOTIFICATIONS` (Android 13+)
- `BLUETOOTH_CONNECT` (for headset PTT discovery)
- `MODIFY_AUDIO_SETTINGS`, `WAKE_LOCK`, `INTERNET`, `ACCESS_NETWORK_STATE`
- A foreground service `ZelloForegroundService` with
  `android:foregroundServiceType="microphone"` so PTT keeps working with
  the screen off.

You must **request the runtime permissions** in your host app
(`RECORD_AUDIO`, `POST_NOTIFICATIONS`, `BLUETOOTH_CONNECT`) using
`permission_handler` or your tool of choice before calling `connect()`.

Then wire the real Zello SDK calls inside
`android/src/main/kotlin/com/zello/flutter/ZelloSdkAdapter.kt` — every
TODO in that file is a single SDK call (one line typically). The channel
plumbing (`ZelloPlugin.kt`) does not need to change.

### 3. iOS wiring

In `ios/zello.podspec` (already scaffolded), uncomment **one** of:

```ruby
# CocoaPods
s.dependency 'ZelloChannelKit', '~> 1.0'

# Or vendored XCFramework
# s.vendored_frameworks = 'Frameworks/ZelloSDK.xcframework'
```

In the **host app**'s `ios/Runner/Info.plist` add:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Used for push-to-talk voice.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>push-to-talk</string>
</array>
```

In the **host app**'s `Runner.entitlements` add:

```xml
<key>com.apple.developer.push-to-talk</key>
<true/>
```

…and enable the **Push to Talk** capability in Xcode (Signing & Capabilities).
Without that entitlement, PT calls will fail silently — set
`enableApplePushToTalk: false` in `ZelloConfig` if you cannot get the
entitlement yet (background PTT will then be limited).

The plugin already configures `AVAudioSession` for
`playAndRecord / .voiceChat / .allowBluetooth / .defaultToSpeaker`.

Wire the real Zello iOS SDK calls inside
`ios/Classes/ZelloSdkAdapter.swift` — same pattern as Android, every TODO
is one SDK call.

### 4. Backend token minting (auth)

The plugin only accepts a **short-lived JWT (RS256)** in `connect(token:)`.
It must **never** see the issuer private key.

Your backend should:

1. Hold the Zello issuer + RS256 private key in a secret store.
2. Mint a JWT per user / per session with a short expiry (e.g. 60–120 s).
3. Return the JWT to the app over HTTPS.

The Flutter app simply receives the token and passes it to `connect()`.

## Threading & lifecycle

- All `MethodChannel.Result` and `EventSink` calls are dispatched on the
  platform main thread (`Handler(Looper.getMainLooper())` on Android,
  `DispatchQueue.main` on iOS).
- The plugin holds a single native client per Flutter engine. `dispose()`
  cancels native listeners, tears down the session, and stops the
  Android foreground service.
- Auto-reconnect attempts from the native SDK are surfaced as
  `ZelloReconnectAttempt` events — never swallowed.

## Manual device-test checklist

The unit tests cover the Dart layer with a mocked `MethodChannel`. The
native voice path must be exercised on real hardware:

1. Connect on Android, lock the screen, press PTT (button or wired) — TX
   audio reaches the channel; foreground-service notification is visible.
2. Receive a transmission while the app is backgrounded — RX audio plays
   through the speaker / Bluetooth headset.
3. Kill network connectivity for 10 s, restore — `ZelloReconnectAttempt`
   then `ZelloConnectionStateChanged(connected)` arrive in Dart.
4. iOS: with the PTT entitlement, background PTT keeps working and the
   system PTT UI appears in Control Center.
5. iOS: route audio to a Bluetooth headset — `AVAudioSession` switches
   without dropping the session.
6. Hardware PTT button on a Sonim/Crosscall device triggers start/stopTalking.
7. Send/receive a text message; verify `ZelloIncomingTextMessage`.
8. `setStatus(ZelloStatus.busy)` — other Zello clients see the new status.

## Known limitations / TODO

- All Zello SDK symbol references are placeholders behind
  `ZelloSdkAdapter` (Android + iOS). Replace the `// TODO: confirm
  against Zello SDK vX` blocks with the real SDK calls from your
  Zello Work portal. The channel layer does not need to change.
- Image messages, location messages, and direct (1:1) voice are not yet
  exposed in the Dart API.
- Channel user-list streaming is not yet exposed; only
  `getChannelState(channel)` snapshots.
- Hardware PTT button auto-routing on Android relies on the Zello SDK's
  built-in handling; custom HID key mapping is not implemented here.
- The iOS Apple-PushToTalk delegate (`ApplePTTBridge`) implements the
  minimum required methods; extend as you wire real Zello TX/RX.
- No federated split (single-package). If/when this plugin gains macOS
  or web support, splitting into platform interface + implementations
  would be appropriate.
- The example app's `android/` and `ios/` projects are not committed —
  run `flutter create --platforms=android,ios .` inside `example/` once,
  then build.
