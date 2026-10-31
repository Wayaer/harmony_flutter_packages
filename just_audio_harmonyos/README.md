# just_audio_harmonyos

`just_audio` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现。

- 当前版本：`0.10.6`
- 对应 Flutter 包：[just_audio 0.10.6](https://pub.dev/packages/just_audio/versions/0.10.6)

## 安装与使用

```yaml
dependencies:
  just_audio: ^0.10.6
  just_audio_harmonyos: ^0.10.6
  audio_session_harmonyos: ^0.2.2
```

```dart
import 'package:just_audio/just_audio.dart';

final AudioPlayer player = AudioPlayer();
await player.setUrl('https://example.com/audio.mp3');
await player.play();
```

## 鸿蒙平台限制

- 音频格式支持范围由系统 AVPlayer 决定。
- 后台播放与锁屏控制需要业务额外接入系统媒体会话。
- 播放在线音频需要 `ohos.permission.INTERNET`，本地文件需要相应的沙箱路径访问权限。

## 兼容版本

- 对应上游 Flutter 插件版本：`just_audio 0.10.6`
- 平台接口依赖：`just_audio_platform_interface: ^4.6.0`
- 依赖 `audio_session_harmonyos: ^0.2.2`
