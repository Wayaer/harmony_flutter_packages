# audio_session_harmonyos

`audio_session` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现。

- 当前版本：`0.2.2`
- 对应 Flutter 包：[audio_session 0.2.2](https://pub.dev/packages/audio_session/versions/0.2.2)

## 安装与使用

```yaml
dependencies:
  audio_session: ^0.2.2
  audio_session_harmonyos: ^0.2.2
```

```dart
import 'package:audio_session/audio_session.dart';

final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration.speech());
await session.setActive(true);
```

鸿蒙扩展能力：

```dart
import 'package:audio_session_harmonyos/audio_session_harmonyos.dart';

final manager = AudioSessionHarmonyOS();
final devices = await manager.getDevices(DevicesFlags.allDevicesFlag);
final volume = await manager.getVolume(AudioVolumeType.media);
final ringMode = await manager.getRingerMode();
```

## 鸿蒙平台限制

- 使用麦克风时需要声明并动态申请 `ohos.permission.MICROPHONE`。
- 音频焦点、中断行为与可用音频属性由系统音频策略和设备能力决定。

## 兼容版本

- 对应上游 Flutter 插件版本：`audio_session 0.2.2`
- 应用侧依赖：`audio_session: ^0.2.2`
