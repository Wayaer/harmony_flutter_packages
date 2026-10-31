# file_selector_harmonyos

`file_selector` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `file_selector 1.1.0`。

## 安装与使用

```yaml
dependencies:
  file_selector: ^1.1.0
  file_selector_harmonyos: ^1.1.0
```

```bash
flutter pub get
```

插件通过 `dartPluginClass` 自动注册，业务代码直接使用 `file_selector` 的 API 即可。

```dart
import 'package:file_selector/file_selector.dart';

const XTypeGroup typeGroup = XTypeGroup(
  label: 'text',
  extensions: <String>['txt', 'json'],
  mimeTypes: <String>['text/plain', 'application/json'],
);
final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
```

## 鸿蒙平台限制

- `confirmButtonText` 在鸿蒙端不生效，系统选择器确认按钮文案无法自定义。
- `uniformTypeIdentifiers` 仅 iOS / macOS 生效，`webWildCards` 仅 Web 生效。
- MIME 过滤依赖内置映射表，未收录的自定义 MIME 类型会被忽略，建议同时传入 `extensions`。
- 选择器和另存为返回的是系统 `file://docs/...` URI；沙箱外路径无法直接转成 `dart:io` 可写入的路径，此时 `getSavePath()` 会回退返回该 URI。

## 兼容版本

- 对应上游 Flutter 插件版本：`file_selector 1.1.0`
- 平台接口依赖：`file_selector_platform_interface: ^2.7.0`
