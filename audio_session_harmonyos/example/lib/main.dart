import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AudioSessionExampleApp());
}

class AudioSessionExampleApp extends StatelessWidget {
  const AudioSessionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioSession',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const AudioSessionPage(),
    );
  }
}

class AudioSessionPage extends StatefulWidget {
  const AudioSessionPage({super.key});

  @override
  State<AudioSessionPage> createState() => _AudioSessionPageState();
}

class _AudioSessionPageState extends State<AudioSessionPage> {
  final logs = <String>[];
  StreamSubscription<AudioInterruptionEvent>? subscription;

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> configureSpeech() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    listenInterruptions(session);
    log('已配置语音会话（speech）');
    await setActive(session, true);
  }

  Future<void> configureMusic() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    listenInterruptions(session);
    log('已配置音乐会话（music）');
    await setActive(session, true);
  }

  void listenInterruptions(AudioSession session) {
    subscription?.cancel();
    subscription = session.interruptionEventStream.listen((event) {
      log('中断事件：begin=${event.begin} type=${event.type}');
    });
  }

  Future<void> setActive(AudioSession session, bool active) async {
    final succeeded = await session.setActive(active);
    log('setActive($active) => $succeeded');
  }

  Future<void> deactivateSession() async {
    final session = await AudioSession.instance;
    await setActive(session, false);
  }

  void log(String message) {
    setState(() {
      logs.insert(0, message);
      if (logs.length > 20) {
        logs.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Session')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: configureSpeech, child: const Text('语音会话')),
                ElevatedButton(onPressed: configureMusic, child: const Text('音乐会话')),
                OutlinedButton(onPressed: deactivateSession, child: const Text('取消激活')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('暂无日志'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) =>
                        Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(logs[index])),
                  ),
          ),
        ],
      ),
    );
  }
}
