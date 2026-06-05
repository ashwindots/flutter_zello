import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zello/zello.dart';
import 'package:zello/src/channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const method = MethodChannel(ZelloChannels.method);
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(method, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getChannelState':
          return <String, Object?>{
            'name': call.arguments['channel'],
            'isConnected': true,
            'isConnecting': false,
            'usersOnline': 3,
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(method, null);
  });

  test('initialize forwards config to native', () async {
    await Zello.instance.initialize(
      config: const ZelloConfig(appKey: 'k'),
    );
    expect(calls.single.method, 'initialize');
    expect(calls.single.arguments['appKey'], 'k');
  });

  test('connect requires initialize first', () async {
    final z = Zello.test();
    expect(
      () => z.connect(network: 'n', token: 't'),
      throwsA(isA<ZelloException>()
          .having((e) => e.code, 'code', 'not_initialized')),
    );
  });

  test('startTalking + stopTalking forward channel name', () async {
    await Zello.instance.initialize(
      config: const ZelloConfig(appKey: 'k'),
    );
    calls.clear();
    await Zello.instance.startTalking('alpha');
    await Zello.instance.stopTalking();
    expect(calls.map((c) => c.method).toList(),
        <String>['startTalking', 'stopTalking']);
    expect(calls.first.arguments['channel'], 'alpha');
  });

  test('sendTextMessage forwards channel + text', () async {
    await Zello.instance.initialize(
      config: const ZelloConfig(appKey: 'k'),
    );
    calls.clear();
    await Zello.instance.sendTextMessage('alpha', 'hi');
    expect(calls.single.arguments['channel'], 'alpha');
    expect(calls.single.arguments['text'], 'hi');
  });

  test('setStatus uses wire names', () async {
    await Zello.instance.initialize(
      config: const ZelloConfig(appKey: 'k'),
    );
    calls.clear();
    await Zello.instance.setStatus(ZelloStatus.busy);
    expect(calls.single.arguments['status'], 'busy');
  });

  test('getChannelState decodes map', () async {
    await Zello.instance.initialize(
      config: const ZelloConfig(appKey: 'k'),
    );
    final c = await Zello.instance.getChannelState('alpha');
    expect(c.name, 'alpha');
    expect(c.isConnected, true);
    expect(c.usersOnline, 3);
  });

  test('PlatformException is mapped to ZelloException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(method, (_) async {
      throw PlatformException(code: 'permission_denied', message: 'denied');
    });
    final z = Zello.test();
    await expectLater(
      z.initialize(config: const ZelloConfig(appKey: 'k')),
      throwsA(isA<ZelloException>()
          .having((e) => e.code, 'code', 'permission_denied')),
    );
  });
}
