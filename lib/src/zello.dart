import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'channels.dart';
import 'events/zello_event.dart';
import 'events/zello_event_codec.dart';
import 'exceptions.dart';
import 'models/zello_channel.dart';
import 'models/zello_connection_state.dart';
import 'models/zello_status.dart';
import 'zello_config.dart';

/// Main facade for the Zello plugin.
///
/// All methods are asynchronous. Native errors are surfaced as
/// [ZelloException]; never silently swallowed. Listen to [events] for
/// streaming updates (incoming voice, text, talk-state, reconnects, etc.).
///
/// Typical usage:
///
/// ```dart
/// await Zello.instance.initialize(config: ZelloConfig(appKey: '...'));
/// final sub = Zello.instance.events.listen((e) { /* handle */ });
/// await Zello.instance.connect(network: 'mynet', token: jwt);
/// await Zello.instance.startTalking('dispatch');
/// // ... release PTT ...
/// await Zello.instance.stopTalking();
/// ```
class Zello {
  Zello._();

  /// Singleton instance. The plugin holds a single native client.
  static final Zello instance = Zello._();

  /// Visible-for-testing constructor that lets tests inject custom channels.
  @visibleForTesting
  factory Zello.test({
    MethodChannel? method,
    EventChannel? events,
  }) {
    final z = Zello._();
    if (method != null) z._method = method;
    if (events != null) z._eventChannel = events;
    return z;
  }

  MethodChannel _method = const MethodChannel(ZelloChannels.method);
  EventChannel _eventChannel = const EventChannel(ZelloChannels.events);

  Stream<ZelloEvent>? _eventStream;
  StreamSubscription<ZelloEvent>? _internalSub;

  final ValueNotifier<ZelloConnectionState> _connectionState =
      ValueNotifier<ZelloConnectionState>(ZelloConnectionState.disconnected);

  bool _initialized = false;

  /// Observable connection state. Updated as the native SDK reports
  /// connect / reconnect / disconnect transitions.
  ValueListenable<ZelloConnectionState> get connectionState => _connectionState;

  /// Broadcast stream of all native events (voice, text, presence, errors).
  ///
  /// The stream is lazily created on first read and remains hot for the
  /// lifetime of the plugin.
  Stream<ZelloEvent> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map<ZelloEvent>(ZelloEventCodec.decode)
        .asBroadcastStream();
    // Keep an internal subscription so we can update connectionState even
    // when the consumer hasn't subscribed yet.
    _internalSub ??= _eventStream!.listen(_onInternalEvent, onError: (_) {});
    return _eventStream!;
  }

  void _onInternalEvent(ZelloEvent event) {
    if (event is ZelloConnectionStateChanged) {
      _connectionState.value = event.state;
    }
  }

  /// Initialize the plugin. Must be called once before [connect]. Safe to
  /// call again with a different [config]; the native SDK will be
  /// re-configured.
  Future<void> initialize({required ZelloConfig config}) async {
    await _invoke<void>('initialize', config.toMap());
    // Force-subscribe so connection state updates start flowing.
    events;
    _initialized = true;
  }

  /// Connect to a Zello Work [network] using a short-lived JWT [token]
  /// minted by your backend. The plugin never handles the issuer private key.
  Future<void> connect({
    required String network,
    required String token,
    String? username,
  }) async {
    _ensureInitialized();
    await _invoke<void>('connect', <String, Object?>{
      'network': network,
      'token': token,
      if (username != null) 'username': username,
    });
  }

  /// Disconnect from the current Zello network. Idempotent.
  Future<void> disconnect() => _invoke<void>('disconnect');

  /// Begin transmitting audio to [channel]. Wire this to the PTT button's
  /// press event. Must be paired with [stopTalking].
  Future<void> startTalking(String channel) =>
      _invoke<void>('startTalking', <String, Object?>{'channel': channel});

  /// Stop transmitting. Wire this to the PTT button's release event.
  Future<void> stopTalking() => _invoke<void>('stopTalking');

  /// Send a text message to [channel].
  Future<void> sendTextMessage(String channel, String text) =>
      _invoke<void>('sendTextMessage', <String, Object?>{
        'channel': channel,
        'text': text,
      });

  /// Update the user's presence/status (e.g. available, busy).
  Future<void> setStatus(ZelloStatus status) =>
      _invoke<void>('setStatus', <String, Object?>{'status': status.wireName});

  /// Fetch the current state of a channel: connected/connecting, member
  /// count, etc.
  Future<ZelloChannel> getChannelState(String channel) async {
    final map = await _invoke<Map<Object?, Object?>>(
      'getChannelState',
      <String, Object?>{'channel': channel},
    );
    return ZelloChannel.fromMap(Map<String, Object?>.from(map ?? const {}));
  }

  /// Release native resources. After [dispose] you must call [initialize]
  /// again before any other API.
  Future<void> dispose() async {
    await _internalSub?.cancel();
    _internalSub = null;
    _eventStream = null;
    _initialized = false;
    try {
      await _method.invokeMethod<void>('dispose');
    } on PlatformException catch (_) {
      // best-effort
    }
  }

  // -- internals -------------------------------------------------------------

  void _ensureInitialized() {
    if (!_initialized) {
      throw ZelloException(
        code: 'not_initialized',
        message: 'Zello.initialize() must be awaited before this call.',
      );
    }
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _method.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw ZelloException(
        code: e.code,
        message: e.message ?? 'Native Zello call failed',
        details: e.details,
      );
    } on MissingPluginException catch (e) {
      throw ZelloException(
        code: 'missing_plugin',
        message: e.message ?? 'Zello plugin not registered on this platform',
      );
    }
  }
}
