import '../models/zello_connection_state.dart';
import '../models/zello_message.dart';
import '../models/zello_user.dart';
import 'zello_event.dart';

/// Decodes raw `Map`s coming over the EventChannel into typed [ZelloEvent].
///
/// Every event payload has the shape:
///   `{ "type": "<event_name>", ...fields }`
class ZelloEventCodec {
  ZelloEventCodec._();

  static ZelloEvent decode(Object? raw) {
    if (raw is! Map) {
      return ZelloUnknownEvent(type: 'invalid', payload: const {});
    }
    final map = Map<String, Object?>.from(raw);
    final type = map['type'] as String? ?? 'unknown';

    switch (type) {
      case 'connectionStateChanged':
        return ZelloConnectionStateChanged(
          ZelloConnectionState.fromWire(map['state'] as String?),
          reason: map['reason'] as String?,
        );
      case 'incomingVoiceStarted':
        return ZelloIncomingVoiceStarted(
          channel: map['channel'] as String? ?? '',
          from: ZelloUser.fromMap(
            Map<String, Object?>.from(
              (map['from'] as Map?) ?? const <String, Object?>{},
            ),
          ),
        );
      case 'incomingVoiceStopped':
        return ZelloIncomingVoiceStopped(
          channel: map['channel'] as String? ?? '',
          from: map['from'] as String? ?? '',
        );
      case 'outgoingTalkStateChanged':
        return ZelloOutgoingTalkStateChanged(
          isTalking: map['isTalking'] as bool? ?? false,
          channel: map['channel'] as String?,
        );
      case 'incomingTextMessage':
        return ZelloIncomingTextMessage(
          ZelloMessage.fromMap(
            Map<String, Object?>.from(
              (map['message'] as Map?) ?? const <String, Object?>{},
            ),
          ),
        );
      case 'channelStatusChanged':
        return ZelloChannelStatusChanged(
          channel: map['channel'] as String? ?? '',
          isConnected: map['isConnected'] as bool? ?? false,
          isConnecting: map['isConnecting'] as bool? ?? false,
        );
      case 'reconnectAttempt':
        return ZelloReconnectAttempt(
          attempt: (map['attempt'] as num?)?.toInt() ?? 0,
          delayMs: (map['delayMs'] as num?)?.toInt(),
        );
      case 'error':
        return ZelloErrorEvent(
          code: map['code'] as String? ?? 'unknown',
          message: map['message'] as String? ?? '',
        );
      default:
        return ZelloUnknownEvent(type: type, payload: map);
    }
  }
}
