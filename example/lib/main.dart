import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zello/zello.dart';

void main() => runApp(const ZelloDemoApp());

class ZelloDemoApp extends StatelessWidget {
  const ZelloDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Zello demo',
        theme:
            ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepOrange),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _networkCtrl = TextEditingController(text: 'demo.zellowork.com');
  final _tokenCtrl = TextEditingController();
  final _channelCtrl = TextEditingController(text: 'All Users');

  final List<String> _log = <String>[];
  StreamSubscription<ZelloEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Zello.instance.initialize(
        config: const ZelloConfig(
          appKey: 'REPLACE_WITH_ZELLO_SDK_KEY',
          channelDisplayName: 'Zello demo',
        ),
      );
    } on ZelloException catch (e) {
      _push('init failed: $e');
    }
    _sub = Zello.instance.events.listen((e) => _push(_describe(e)));
  }

  String _describe(ZelloEvent e) => switch (e) {
        ZelloConnectionStateChanged(:final state) =>
          'connection -> ${state.name}',
        ZelloIncomingVoiceStarted(:final channel, :final from) =>
          'RX start [$channel] from ${from.username}',
        ZelloIncomingVoiceStopped(:final channel, :final from) =>
          'RX stop  [$channel] from $from',
        ZelloOutgoingTalkStateChanged(:final isTalking, :final channel) =>
          'TX ${isTalking ? "on" : "off"}${channel != null ? " [$channel]" : ""}',
        ZelloIncomingTextMessage(:final message) =>
          'msg [${message.channel}] ${message.from}: ${message.text}',
        ZelloChannelStatusChanged(:final channel, :final isConnected) =>
          'channel $channel ${isConnected ? "connected" : "not connected"}',
        ZelloReconnectAttempt(:final attempt) => 'reconnect attempt #$attempt',
        ZelloErrorEvent(:final code, :final message) => 'error[$code] $message',
        ZelloUnknownEvent(:final type) => 'unknown event $type',
      };

  void _push(String line) {
    if (!mounted) return;
    setState(() {
      _log.insert(
          0, '${DateTime.now().toIso8601String().substring(11, 19)}  $line');
      if (_log.length > 200) _log.removeLast();
    });
  }

  Future<void> _connect() async {
    try {
      await Zello.instance.connect(
        network: _networkCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
      );
    } on ZelloException catch (e) {
      _push('connect failed: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await Zello.instance.disconnect();
    } on ZelloException catch (e) {
      _push('disconnect failed: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    Zello.instance.dispose();
    _networkCtrl.dispose();
    _tokenCtrl.dispose();
    _channelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zello demo'),
        actions: [
          ValueListenableBuilder<ZelloConnectionState>(
            valueListenable: Zello.instance.connectionState,
            builder: (_, state, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(label: Text(state.name)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _networkCtrl,
              decoration: const InputDecoration(labelText: 'Network'),
            ),
            TextField(
              controller: _tokenCtrl,
              decoration: const InputDecoration(labelText: 'JWT token'),
              obscureText: true,
            ),
            TextField(
              controller: _channelCtrl,
              decoration: const InputDecoration(labelText: 'Channel'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _connect,
                    child: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _disconnect,
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: _PttButton(channel: _channelCtrl.text)),
            const SizedBox(height: 16),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (_, i) => Text(
                  _log[i],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PttButton extends StatefulWidget {
  final String channel;
  const _PttButton({required this.channel});

  @override
  State<_PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends State<_PttButton> {
  bool _down = false;

  Future<void> _press() async {
    setState(() => _down = true);
    try {
      await Zello.instance.startTalking(widget.channel);
    } on ZelloException {
      setState(() => _down = false);
    }
  }

  Future<void> _release() async {
    setState(() => _down = false);
    try {
      await Zello.instance.stopTalking();
    } on ZelloException {/* ignore */}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _down ? Colors.red : Colors.deepOrange,
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        alignment: Alignment.center,
        child: Text(
          _down ? 'TALKING' : 'PUSH TO TALK',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
