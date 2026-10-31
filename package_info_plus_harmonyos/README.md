# package_info_plus_harmonyos

`package_info_plus` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `package_info_plus 10.2.2`。

## 安装与使用

```yaml
dependencies:
  package_info_plus: ^10.2.2
  package_info_plus_harmonyos: ^10.2.2
```

```dart
import 'package:package_info_plus/package_info_plus.dart';

final PackageInfo info = await PackageInfo.fromPlatform();
print(info.appName);
print(info.packageName);
print(info.version);
print(info.buildNumber);
```

## 鸿蒙平台限制

- `installerStore` 在部分设备或分发渠道上可能为空。
- 构建号与版本号来自 `AppScope/app.json5`，需保证打包配置正确。
- 签名摘要依赖安装包签名信息，调试包与正式包可能不同。

## 兼容版本

- 对应上游 Flutter 插件版本：`package_info_plus 10.2.2`
- 平台接口依赖：`package_info_plus_platform_interface: ^4.1.0`
