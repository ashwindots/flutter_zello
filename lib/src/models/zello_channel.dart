import 'package:meta/meta.dart';

/// Snapshot of a Zello channel.
@immutable
class ZelloChannel {
  final String name;
  final bool isConnected;
  final bool isConnecting;
  final int usersOnline;
  final String? title;

  const ZelloChannel({
    required this.name,
    required this.isConnected,
    required this.isConnecting,
    required this.usersOnline,
    this.title,
  });

  factory ZelloChannel.fromMap(Map<String, Object?> map) => ZelloChannel(
        name: map['name'] as String? ?? '',
        isConnected: map['isConnected'] as bool? ?? false,
        isConnecting: map['isConnecting'] as bool? ?? false,
        usersOnline: (map['usersOnline'] as num?)?.toInt() ?? 0,
        title: map['title'] as String?,
      );
}
