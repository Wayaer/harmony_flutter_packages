# vibration_harmonyos

`vibration` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现。

- 当前版本：`3.2.1`
- 对应 Flutter 包：[vibration 3.2.1](https://pub.dev/packages/vibration/versions/3.2.1)

## 安装与使用

```yaml
dependencies:
  vibration: ^3.2.1
  vibration_harmonyos: ^3.2.1
```

```dart
import 'package:vibration/vibration.dart';

await Vibration.vibrate();
await Vibration.vibrate(duration: 1000);
await Vibration.cancel();
```

鸿蒙扩展能力（仅鸿蒙平台可用）：

```dart
import 'package:vibration_harmonyos/vibration_harmonyos.dart';

final plugin = VibrationPlatform.instance as VibrationHarmonyOS;

await plugin.vibrate(
  vibrateEffect: const VibratePreset(count: 100),
  vibrateAttribute: const VibrateAttribute(usage: 'alarm'),
);

await plugin.vibrate(
  vibrateEffect: VibrateFromFile(hapticFd: HapticFileDescriptor(data: bytes)),
  vibrateAttribute: const VibrateAttribute(usage: 'alarm'),
);
```

## 鸿蒙平台限制

- 需要申请 `ohos.permission.VIBRATE` 权限。
- `pattern` / `intensities` 暂未映射到鸿蒙原生振动效果。
- 自定义振动配置文件仅部分设备支持；模拟器或无马达设备上振动无实际效果。

## 兼容版本

- 对应上游 Flutter 插件版本：`vibration 3.2.1`
- 平台接口依赖：`vibration_platform_interface: ^0.1.1`
- 依赖 `device_info_plus_harmonyos: ^13.3.0`
