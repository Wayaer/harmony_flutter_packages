# video_player_harmonyos

`video_player` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `video_player 2.14.1`。

## 安装与使用

```yaml
dependencies:
  video_player: ^2.14.1
  video_player_harmonyos: ^2.14.1
```

```bash
flutter pub get
```

插件通过 `dartPluginClass` 自动注册，业务代码直接使用 `video_player` 的 API 即可。

```dart
import 'package:video_player/video_player.dart';

final VideoPlayerController controller = VideoPlayerController.asset('assets/video.mp4');
await controller.initialize();
await controller.play();

final VideoPlayerController fileController = VideoPlayerController.file(File(path));

final VideoPlayerController networkController =
    VideoPlayerController.networkUrl(Uri.parse('https://example.com/video.mp4'));
```

## 鸿蒙平台限制

- `getVideoTracks()` / `selectVideoTrack()` 已支持，能力取决于设备与系统 AVPlayer 返回的轨道信息。
- `setPreventsDisplaySleepDuringVideoPlayback()` 已实现，通过 `setWindowKeepScreenOn` 控制播放期间常亮。
- 音轨切换能力依赖设备与系统媒体能力，部分格式可能只返回空音轨列表。
- `VideoViewType.platformView` 暂未接入，内部统一使用纹理（textureView）渲染。
- `setAllowBackgroundPlayback()` 仅记录配置，真正的后台存活需要宿主配置鸿蒙后台任务。
- 视频格式支持范围由系统 AVPlayer 决定。
- 运行环境要求：Flutter `>=3.44.0`、Dart `>=3.12.0`（由上游 `video_player 2.14.1` 要求）。
- 播放在线视频需要 `ohos.permission.INTERNET`。

## 兼容版本

- 对应上游 Flutter 插件版本：`video_player 2.14.1`
- 平台接口依赖：`video_player_platform_interface: ^6.9.0`
