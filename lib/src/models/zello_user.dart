import 'package:meta/meta.dart';

import 'zello_status.dart';

/// A user as reported by the Zello SDK.
@immutable
class ZelloUser {
  final String username;
  final String? displayName;
  final ZelloStatus status;

  const ZelloUser({
    required this.username,
    this.displayName,
    this.status = ZelloStatus.available,
  });

  factory ZelloUser.fromMap(Map<String, Object?> map) => ZelloUser(
        username: map['username'] as String? ?? '',
        displayName: map['displayName'] as String?,
        status: ZelloStatus.fromWire(map['status'] as String?),
      );
}
