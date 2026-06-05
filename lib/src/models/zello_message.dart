import 'package:meta/meta.dart';

/// A text message exchanged on a channel.
@immutable
class ZelloMessage {
  final String channel;
  final String from;
  final String text;
  final DateTime receivedAt;

  const ZelloMessage({
    required this.channel,
    required this.from,
    required this.text,
    required this.receivedAt,
  });

  factory ZelloMessage.fromMap(Map<String, Object?> map) {
    final ts = (map['timestampMs'] as num?)?.toInt();
    return ZelloMessage(
      channel: map['channel'] as String? ?? '',
      from: map['from'] as String? ?? '',
      text: map['text'] as String? ?? '',
      receivedAt:
          ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now(),
    );
  }
}
