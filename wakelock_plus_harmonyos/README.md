# wakelock_plus_harmonyos

`wakelock_plus` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `wakelock_plus 1.8.2`。

## 安装与使用

```yaml
dependencies:
  wakelock_plus: ^1.8.2
  wakelock_plus_harmonyos: ^1.8.2
```

```dart
import 'package:wakelock_plus/wakelock_plus.dart';

await WakelockPlus.enable();
await WakelockPlus.disable();
await WakelockPlus.toggle(enable: true);

final bool enabled = await WakelockPlus.enabled;
```

## 鸿蒙平台限制

- 常亮状态作用于当前窗口，应用退到后台后由系统策略接管。
- 部分设备在熄屏策略下仍可能自动锁屏，与系统省电设置有关。
- 运行环境要求：Flutter `>=3.44.0`、Dart `>=3.12.0`（由上游 `wakelock_plus 1.8.2` 与平台接口要求）。

## 兼容版本

- 对应上游 Flutter 插件版本：`wakelock_plus 1.8.2`
- 平台接口依赖：`wakelock_plus_platform_interface: ^1.7.0`
