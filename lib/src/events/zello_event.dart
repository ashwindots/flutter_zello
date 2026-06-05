import 'package:meta/meta.dart';

import '../models/zello_connection_state.dart';
import '../models/zello_message.dart';
import '../models/zello_user.dart';

/// Sealed hierarchy of native -> Dart streaming events.
///
/// Use a `switch` (Dart 3 pattern matching) to handle exhaustively:
///
/// ```dart
/// switch (event) {
///   ZelloConnectionStateChanged(:final state) => ...,
///   ZelloIncomingVoiceStarted(:final from, :final channel) => ...,
///   ZelloIncomingVoiceStopped() => ...,
///   ZelloIncomingTextMessage(:final message) => ...,
///   ZelloOutgoingTalkStateChanged(:final isTalking) => ...,
///   ZelloChannelStatusChanged(:final channel, :final isConnected) => ...,
///   ZelloErrorEvent(:final code, :final message) => ...,
/// }
/// ```
@immutable
sealed class ZelloEvent {
  const ZelloEvent();
}

class ZelloConnectionStateChanged extends ZelloEvent {
  final ZelloConnectionState state;
  final String? reason;
  const ZelloConnectionStateChanged(this.state, {this.reason});
}

class ZelloIncomingVoiceStarted extends ZelloEvent {
  final String channel;
  final ZelloUser from;
  const ZelloIncomingVoiceStarted({required this.channel, required this.from});
}

class ZelloIncomingVoiceStopped extends ZelloEvent {
  final String channel;
  final String from;
  const ZelloIncomingVoiceStopped({required this.channel, required this.from});
}

class ZelloOutgoingTalkStateChanged extends ZelloEvent {
  final bool isTalking;
  final String? channel;
  const ZelloOutgoingTalkStateChanged({
    required this.isTalking,
    this.channel,
  });
}

class ZelloIncomingTextMessage extends ZelloEvent {
  final ZelloMessage message;
  const ZelloIncomingTextMessage(this.message);
}

class ZelloChannelStatusChanged extends ZelloEvent {
  final String channel;
  final bool isConnected;
  final bool isConnecting;
  const ZelloChannelStatusChanged({
    required this.channel,
    required this.isConnected,
    required this.isConnecting,
  });
}

class ZelloReconnectAttempt extends ZelloEvent {
  final int attempt;
  final int? delayMs;
  const ZelloReconnectAttempt({required this.attempt, this.delayMs});
}

class ZelloErrorEvent extends ZelloEvent {
  final String code;
  final String message;
  const ZelloErrorEvent({required this.code, required this.message});
}

/// Fallback for events the Dart side doesn't yet model — exposes the raw
/// payload so consumers can adopt new native events without a plugin bump.
class ZelloUnknownEvent extends ZelloEvent {
  final String type;
  final Map<String, Object?> payload;
  const ZelloUnknownEvent({required this.type, required this.payload});
}
