import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'src/messages.g.dart';

export 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// An OHOS implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [OhosVideoPlayerApi].
class VideoPlayerHarmonyOS extends VideoPlayerPlatform {
  final OhosVideoPlayerApi _api = OhosVideoPlayerApi();

  static void registerWith() {
    VideoPlayerPlatform.instance = VideoPlayerHarmonyOS();
  }

  @override
  Future<void> init() => _api.initialize();

  @override
  Future<void> dispose(int playerId) => _api.dispose(playerId);

  @override
  Future<int?> create(DataSource dataSource) async {
    String? asset;
    String? uri;
    final httpHeaders = dataSource.httpHeaders.isEmpty
        ? null
        : Map<String?, String?>.fromEntries(dataSource.httpHeaders.entries
            .map((e) => MapEntry(e.key, e.value)));

    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        break;
      case DataSourceType.network:
        uri = dataSource.uri;
        break;
      case DataSourceType.file:
        uri = dataSource.uri?.startsWith('fd://') == true
            ? dataSource.uri
            : 'fd://${await VideoPlayerHarmonyOS.getFileFdByPath(dataSource.uri!)}';
        break;
      default:
        uri = dataSource.uri;
    }

    final message = CreateMessage(
      httpHeaders: httpHeaders ?? <String?, String?>{},
      asset: asset,
      uri: uri,
      viewType: PlatformVideoViewType.textureView,
    );

    return _api.create(message);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    return _api.setLooping(playerId, looping);
  }

  @override
  Future<void> play(int playerId) {
    return _api.play(playerId);
  }

  @override
  Future<void> pause(int playerId) {
    return _api.pause(playerId);
  }

  @override
  Future<void> setVolume(int playerId, double volume) {
    return _api.setVolume(playerId, volume);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) {
    assert(speed > 0);
    return _api.setPlaybackSpeed(playerId, speed);
  }

  @override
  Future<void> seekTo(int playerId, Duration position) {
    return _api.seekTo(playerId, position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    final int positionMs = await _api.position(playerId);
    return Duration(milliseconds: positionMs);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _eventChannelFor(playerId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: map['duration'] as int),
            size: Size((map['width'] as num?)?.toDouble() ?? 0.0,
                (map['height'] as num?)?.toDouble() ?? 0.0),
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
          );
        case 'completed':
          return VideoEvent(
            eventType: VideoEventType.completed,
          );
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List<dynamic>;
          return VideoEvent(
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
            eventType: VideoEventType.bufferingUpdate,
          );
        case 'bufferingStart':
          return VideoEvent(eventType: VideoEventType.bufferingStart);
        case 'bufferingEnd':
          return VideoEvent(eventType: VideoEventType.bufferingEnd);
        case 'isPlayingStateUpdate':
          return VideoEvent(
            eventType: VideoEventType.isPlayingStateUpdate,
            isPlaying: map['isPlaying'] as bool,
          );
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Widget buildView(int playerId) {
    return Texture(textureId: playerId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api.setMixWithOthers(mixWithOthers);
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/videoPlayer/videoEvents$textureId');
  }

  static const Map<VideoFormat, String> videoFormatStringMap =
      <VideoFormat, String>{
    VideoFormat.ss: 'ss',
    VideoFormat.hls: 'hls',
    VideoFormat.dash: 'dash',
    VideoFormat.other: 'other',
  };

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List<dynamic>;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }

  static final _channel = MethodChannel('plugins.flutter.io/video_player_ohos');

  static Future<int> getFileFdByPath(String? path) async {
    int fileFd = -1;
    if (path == null) return fileFd;
    return await _channel.invokeMethod('getFileFdByPath', {'filePath': path});
  }
}
