# device_info_plus_harmonyos

`device_info_plus` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `device_info_plus 13.3.0`。

## 安装与使用

```yaml
dependencies:
  device_info_plus: ^13.3.0
  device_info_plus_harmonyos: ^13.3.0
```

```dart
import 'package:device_info_plus_harmonyos/device_info_plus_harmonyos.dart';

final DeviceInfoPlusOhosPlugin deviceInfo = DeviceInfoPlusOhosPlugin();
final OhosDeviceInfo info = await deviceInfo.ohosInfo;
print(info.osFullName);
print(info.productModel);
```

## 鸿蒙平台限制

- `serial`、`udid` 需要系统级权限 `ohos.permission.sec.ACCESS_UDID`，普通应用无法获取。
- `hardwareProfile` 在 API 9 之后已废弃，不同系统版本可能返回空值。

## 兼容版本

- 对应上游 Flutter 插件版本：`device_info_plus 13.3.0`
- 平台接口依赖：`device_info_plus_platform_interface: ^8.1.0`
