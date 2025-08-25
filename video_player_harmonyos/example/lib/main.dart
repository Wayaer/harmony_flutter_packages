import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

const String videoAsset = 'assets/video.mp4';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
        title: 'Video player harmonyos',
        home: Scaffold(
          body: _App(),
          appBar: AppBar(title: Text('Video player harmonyos')),
        )),
  );
}

class _App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.insert_drive_file), text: 'Asset'),
            Tab(icon: Icon(Icons.cloud), text: 'Remote'),
            Tab(icon: Icon(Icons.file_open), text: 'LocalFile'),
          ],
        ),
        Expanded(
            child: TabBarView(
          children: <Widget>[
            _AssetVideo(),
            _RemoteVideo(),
            _LocalFileVideo(),
          ],
        ))
      ]),
    );
  }
}

class _AssetVideo extends StatefulWidget {
  @override
  _AssetVideoState createState() => _AssetVideoState();
}

class _AssetVideoState extends State<_AssetVideo> {
  VideoPlayerController? _controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }

  void initialize() async {
    _controller = VideoPlayerController.asset(videoAsset);
    _controller!.addListener(() {
      setState(() {});
    });
    await _controller!.initialize();
    setState(() {});
    _controller!.play();
  }
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VideoPlayerTab(controller: _controller, title: 'With assets mp4');
  }
}

class _LocalFileVideo extends StatefulWidget {
  @override
  _LocalFileVideoState createState() => _LocalFileVideoState();
}

class _LocalFileVideoState extends State<_LocalFileVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      saveVideo().then((value) async {
        _controller = VideoPlayerController.file(value);
        _controller!.addListener(() {
          setState(() {});
        });
        await _controller!.initialize();
        setState(() {});
        _controller!.play();
      });
    });
  }

  Future<File> saveVideo() async {
    final Directory directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/video.mp4');
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      final bytes = await rootBundle.load(videoAsset);
      file.writeAsBytesSync(bytes.buffer.asUint8List());
    }
    return File(file.path);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VideoPlayerTab(
        controller: _controller, title: 'With local file mp4');
  }
}

class _RemoteVideo extends StatefulWidget {
  @override
  _RemoteVideoState createState() => _RemoteVideoState();
}

class _RemoteVideoState extends State<_RemoteVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }

  void initialize() async {
    _controller = VideoPlayerController.networkUrl(
        Uri.parse('https://media.w3.org/2010/05/sintel/trailer.mp4'));
    _controller!.addListener(() {
      setState(() {});
    });
    await _controller!.initialize();
    setState(() {});
    _controller!.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VideoPlayerTab(controller: _controller, title: 'With remote mp4');
  }
}

class _VideoPlayerTab extends StatelessWidget {
  const _VideoPlayerTab({required this.controller, required this.title});

  final VideoPlayerController? controller;

  final String title;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 20,
        children: <Widget>[
          SizedBox(),
          Text(title),
          if (controller != null)
            AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(controller!),
                  _ControlsOverlay(controller: controller!),
                  VideoProgressIndicator(controller!, allowScrubbing: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  static const List<double> _examplePlaybackRates = <double>[
    0.75,
    1.0,
    1.25,
    1.75,
    2.0,
  ];

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
