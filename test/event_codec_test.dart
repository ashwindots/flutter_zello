import 'package:flutter_test/flutter_test.dart';
import 'package:zello/src/events/zello_event_codec.dart';
import 'package:zello/zello.dart';

void main() {
  test('connectionStateChanged decodes', () {
    final e = ZelloEventCodec.decode({
      'type': 'connectionStateChanged',
      'state': 'connected',
    });
    expect(e, isA<ZelloConnectionStateChanged>());
    expect((e as ZelloConnectionStateChanged).state,
        ZelloConnectionState.connected);
  });

  test('incomingVoiceStarted decodes nested user', () {
    final e = ZelloEventCodec.decode({
      'type': 'incomingVoiceStarted',
      'channel': 'alpha',
      'from': {'username': 'bob', 'displayName': 'Bob', 'status': 'busy'},
    });
    expect(e, isA<ZelloIncomingVoiceStarted>());
    final v = e as ZelloIncomingVoiceStarted;
    expect(v.channel, 'alpha');
    expect(v.from.username, 'bob');
    expect(v.from.status, ZelloStatus.busy);
  });

  test('unknown type falls back to ZelloUnknownEvent', () {
    final e = ZelloEventCodec.decode({'type': 'wat', 'x': 1});
    expect(e, isA<ZelloUnknownEvent>());
    expect((e as ZelloUnknownEvent).type, 'wat');
    expect(e.payload['x'], 1);
  });

  test('non-map decodes to invalid', () {
    final e = ZelloEventCodec.decode('not a map');
    expect(e, isA<ZelloUnknownEvent>());
    expect((e as ZelloUnknownEvent).type, 'invalid');
  });
}
