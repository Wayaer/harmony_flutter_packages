# sensors_plus_harmonyos

`sensors_plus` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `sensors_plus 7.1.1`。

## 安装与使用

```yaml
dependencies:
  sensors_plus: ^7.1.1
  sensors_plus_harmonyos: ^7.1.1
```

```dart
import 'package:sensors_plus/sensors_plus.dart';

accelerometerEventStream().listen((AccelerometerEvent event) {
  print('${event.x}, ${event.y}, ${event.z}');
});

gyroscopeEventStream().listen((GyroscopeEvent event) {});
magnetometerEventStream().listen((MagnetometerEvent event) {});
```

## 鸿蒙平台限制

- 设备不支持某类传感器时，订阅会触发错误回调。
- 实际采样频率受系统调度与硬件能力影响，`samplingPeriod` 只是期望值。
- 后台采集需要业务自行申请长时任务，否则会被系统暂停。

## 兼容版本

- 对应上游 Flutter 插件版本：`sensors_plus 7.1.1`
- 平台接口依赖：`sensors_plus_platform_interface: ^2.0.2`
