import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const VideoPlayerExampleApp());
}

class VideoPlayerExampleApp extends StatelessWidget {
  const VideoPlayerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669))),
      home: const VideoPlayerPage(),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  final List<_VideoSource> _sources = const <_VideoSource>[
    _VideoSource(label: 'v.mp4', location: 'assets/v.mp4', isAsset: true),
    _VideoSource(label: 'h.mp4', location: 'assets/h.mp4', isAsset: true),
    _VideoSource(
      label: 'bee.mp4',
      location: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      isAsset: false,
    ),
  ];

  VideoPlayerController? _controller;
  int _selectedIndex = 0;
  bool _prepared = false;
  bool _looping = false;
  double _volume = 1;
  double _speed = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    open(0);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> open(int index) async {
    final VideoPlayerController? previous = _controller;
    final VideoPlayerController next = _sources[index].createController();
    setState(() {
      _controller = next;
      _selectedIndex = index;
      _prepared = false;
      _error = null;
    });
    await previous?.dispose();
    try {
      await next.initialize();
      await next.setLooping(_looping);
      await next.setPlaybackSpeed(_speed);
      await next.setVolume(_volume);
      if (!mounted || _controller != next) {
        return;
      }
      setState(() => _prepared = true);
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '视频加载失败: $exception');
    }
  }

  Future<void> togglePlay() async {
    final VideoPlayerController? current = _controller;
    if (current == null || !_prepared) {
      return;
    }
    if (current.value.isPlaying) {
      await current.pause();
    } else {
      await current.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    final VideoPlayerController? current = _controller;
    if (current == null || !_prepared) {
      return;
    }
    await current.seekTo(position);
  }

  Future<void> changeSpeed(double value) async {
    _speed = value;
    await _controller?.setPlaybackSpeed(value);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> changeLooping(bool value) async {
    _looping = value;
    await _controller?.setLooping(value);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> changeVolume(double value) async {
    _volume = value;
    await _controller?.setVolume(value);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final VideoPlayerController? current = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
        actions: [IconButton(tooltip: '重新加载', onPressed: () => open(_selectedIndex), icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: 300,
              child: current != null && _prepared
                  ? Center(
                      child: AspectRatio(aspectRatio: current.value.aspectRatio, child: VideoPlayer(current)),
                    )
                  : Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (current != null && _prepared)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: current,
              builder: (BuildContext context, VideoPlayerValue value, Widget? child) {
                final double maxMilliseconds = value.duration.inMilliseconds.toDouble();
                final double positionMilliseconds = value.position.inMilliseconds.toDouble();
                final double sliderMax = maxMilliseconds == 0 ? 1 : maxMilliseconds;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      min: 0,
                      max: sliderMax,
                      value: positionMilliseconds.clamp(0, sliderMax).toDouble(),
                      onChanged: (double milliseconds) => seekTo(Duration(milliseconds: milliseconds.round())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          value.isPlaying ? '播放中' : '已暂停',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          iconSize: 32,
                          tooltip: value.isPlaying ? '暂停' : '播放',
                          onPressed: togglePlay,
                          icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: '回到开头',
                          onPressed: () => seekTo(Duration.zero),
                          icon: const Icon(Icons.replay),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.speed, size: 20, color: colors.primary),
                        const SizedBox(width: 8),
                        Text('播放速度', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<double>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        segments: const <ButtonSegment<double>>[
                          ButtonSegment<double>(value: 0.5, label: Text('0.5x')),
                          ButtonSegment<double>(value: 1, label: Text('1x')),
                          ButtonSegment<double>(value: 1.5, label: Text('1.5x')),
                          ButtonSegment<double>(value: 2, label: Text('2x')),
                        ],
                        selected: <double>{_speed},
                        onSelectionChanged: (Set<double> selection) => changeSpeed(selection.first),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ControlRow(
                      icon: Icons.repeat,
                      label: '循环播放',
                      child: Switch(value: _looping, onChanged: changeLooping),
                    ),
                    _ControlRow(
                      icon: _volume == 0 ? Icons.volume_off : Icons.volume_up,
                      label: '音量 ${(_volume * 100).round()}%',
                      child: SizedBox(
                        width: 160,
                        child: Slider(value: _volume, onChanged: changeVolume),
                      ),
                    ),
                  ],
                );
              },
            )
          else if (current == null || _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('正在准备播放器…', style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 16),
          _Section(
            title: '视频源',
            icon: Icons.video_library_outlined,
            child: Column(
              children: [
                for (int index = 0; index < _sources.length; index++)
                  _SourceTile(source: _sources[index], selected: index == _selectedIndex, onTap: () => open(index)),
              ],
            ),
          ),
          Text(
            '前两个视频使用 VideoPlayerController.asset 直接渲染示例内置的本地文件，第三个使用 VideoPlayerController.networkUrl 加载网络视频；'
            '播放、暂停、seekTo、setPlaybackSpeed、setLooping、setVolume 均为常用控制接口。',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final String minutes = duration.inMinutes.toString().padLeft(2, '0');
    final String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _VideoSource {
  const _VideoSource({required this.label, required this.location, required this.isAsset});

  final String label;
  final String location;
  final bool isAsset;

  VideoPlayerController createController() =>
      isAsset ? VideoPlayerController.asset(location) : VideoPlayerController.networkUrl(Uri.parse(location));
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source, required this.selected, required this.onTap});

  final _VideoSource source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        source.isAsset ? Icons.video_file_outlined : Icons.cloud_outlined,
        color: selected ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(source.label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        source.isAsset ? '本地 asset' : '网络 URL',
        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      onTap: onTap,
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          child,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
