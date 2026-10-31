# path_provider_harmonyos

`path_provider` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `path_provider 2.1.6`。

## 安装与使用

```yaml
dependencies:
  path_provider: ^2.1.6
  path_provider_harmonyos: ^2.1.6
```

```bash
flutter pub get
```

插件通过 `dartPluginClass` 自动注册，业务代码直接使用 `path_provider` 的 API 即可。

```dart
import 'package:path_provider/path_provider.dart';

final Directory tempDir = await getTemporaryDirectory();
final Directory supportDir = await getApplicationSupportDirectory();
final Directory documentsDir = await getApplicationDocumentsDirectory();
final Directory cacheDir = await getApplicationCacheDirectory();
final Directory? downloadsDir = await getDownloadsDirectory();

final List<Directory>? externalDirs = await getExternalStorageDirectories(
  type: StorageDirectory.pictures,
);
```

## 鸿蒙平台限制

- `getLibraryPath()` 在鸿蒙上没有对应概念，调用会抛出 `UnsupportedError`。
- 鸿蒙没有与 Android 等价的公共外部存储目录，`getExternalStoragePaths()` 返回的是应用沙箱内的子目录。
- `getExternalStoragePath()` 与 `getApplicationSupportDirectory()` 在鸿蒙上都返回应用沙箱的 `filesDir`，路径相同。
- 外部存储子目录不存在时会自动创建，创建失败时返回空列表。

## 兼容版本

- 对应上游 Flutter 插件版本：`path_provider 2.1.6`
- 平台接口依赖：`path_provider_platform_interface: ^2.1.0`
- 运行环境要求：Flutter `>=3.38.0`、Dart `>=3.10.0`
