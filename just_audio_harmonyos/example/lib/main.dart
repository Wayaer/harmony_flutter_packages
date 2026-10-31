import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const JustAudioExampleApp());
}

class JustAudioExampleApp extends StatelessWidget {
  const JustAudioExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: SafeArea(child: PlayerPage())),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static final audioSource = AudioSource.uri(
    Uri.parse(
      'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    ),
  );

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    player.setAudioSource(audioSource);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.duration ?? Duration.zero;
              final max = duration.inMilliseconds.toDouble();
              return Column(
                children: [
                  Slider(
                    max: max <= 0 ? 1 : max,
                    value: position.inMilliseconds
                        .clamp(0, max <= 0 ? 1 : max)
                        .toDouble(),
                    onChanged: (value) =>
                        player.seek(Duration(milliseconds: value.round())),
                  ),
                  Text('${position.inSeconds}s / ${duration.inSeconds}s'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing ?? false;
              final loading =
                  state?.processingState == ProcessingState.loading ||
                  state?.processingState == ProcessingState.buffering;
              if (loading) {
                return const CircularProgressIndicator();
              }
              return IconButton(
                iconSize: 64,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: playing ? player.pause : player.play,
              );
            },
          ),
          TextButton(onPressed: player.stop, child: const Text('停止')),
        ],
      ),
    );
  }
}
