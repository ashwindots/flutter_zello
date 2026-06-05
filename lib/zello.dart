/// Zello — Flutter plugin wrapping the native Zello Work Mobile SDKs.
///
/// This is the single entry point. Import this file and use [Zello] to drive
/// connection, push-to-talk, text messaging and presence. All streaming
/// updates are delivered through [Zello.events].
library;

export 'src/zello.dart' show Zello;
export 'src/zello_config.dart';
export 'src/exceptions.dart';
export 'src/models/zello_channel.dart';
export 'src/models/zello_message.dart';
export 'src/models/zello_user.dart';
export 'src/models/zello_status.dart';
export 'src/models/zello_connection_state.dart';
export 'src/events/zello_event.dart';
