# connectivity_plus_harmonyos

`connectivity_plus` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `connectivity_plus 7.3.2`。

## 安装与使用

```yaml
dependencies:
  connectivity_plus: ^7.3.2
  connectivity_plus_harmonyos: ^7.3.2
```

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
final Stream<List<ConnectivityResult>> stream = Connectivity().onConnectivityChanged;
```

## 鸿蒙平台限制

- 需要在 `module.json5` 中声明 `ohos.permission.INTERNET` 与 `ohos.permission.GET_NETWORK_INFO`。
- 网络类型与切换事件由系统连接能力决定，双卡、VPN、蓝牙共享等场景可能与 Android / iOS 表现不同。
- 网络切换事件存在系统级延迟，实时性依赖设备实现。

## 兼容版本

- 对应上游 Flutter 插件版本：`connectivity_plus 7.3.2`
- 平台接口依赖：`connectivity_plus_platform_interface: ^2.1.0`
