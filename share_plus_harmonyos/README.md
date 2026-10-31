# share_plus_harmonyos

`share_plus` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `share_plus 13.3.1`。

## 安装与使用

```yaml
dependencies:
  share_plus: ^13.3.1
  share_plus_harmonyos: ^13.3.1
```

```dart
import 'package:share_plus/share_plus.dart';

await SharePlus.instance.share(
  ShareParams(
    text: 'Flutter HarmonyOS',
    subject: '分享标题',
  ),
);
```

## 鸿蒙平台限制

- `sharePositionOrigin` 不参与鸿蒙端弹窗定位。
- `previewThumbnail` 暂不支持，鸿蒙端不会生效。
- 分享结果回调在部分系统版本上可能无法区分取消与失败。
- 分享文件需要应用对文件路径具备访问权限，大文件建议先复制到应用缓存目录。

## 兼容版本

- 对应上游 Flutter 插件版本：`share_plus 13.3.1`
- 平台接口依赖：`share_plus_platform_interface: ^7.2.0`
