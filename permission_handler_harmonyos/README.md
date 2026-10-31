# permission_handler_harmonyos

`permission_handler` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `permission_handler 13.0.2`。

## 安装与使用

```yaml
dependencies:
  permission_handler: ^13.0.2
  permission_handler_harmonyos: ^13.0.2
```

```dart
import 'package:permission_handler/permission_handler.dart';

final PermissionStatus status = await Permission.camera.request();
if (status.isGranted) {
  // 已授权
}

await openAppSettings();
```

## 鸿蒙平台限制

- 除动态申请外，还必须在 `module.json5` 的 `requestPermissions` 中声明对应权限。
- 部分系统级权限只对系统应用开放，普通应用申请会失败。
- 鸿蒙权限名称与 Android / iOS 并非一一对应，部分 `Permission` 枚举会映射为不支持。
- `ServiceStatus` 为部分支持，依赖系统服务状态。
- 永久拒绝后需要引导用户到应用设置页手动开启。

## 兼容版本

- 对应上游 Flutter 插件版本：`permission_handler 13.0.2`
- 平台接口依赖：`permission_handler_platform_interface: ^4.4.0`
