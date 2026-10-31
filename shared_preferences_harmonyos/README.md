# shared_preferences_harmonyos

`shared_preferences` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `shared_preferences 2.5.6`。

## 安装与使用

```yaml
dependencies:
  shared_preferences: ^2.5.6
  shared_preferences_harmonyos: ^2.5.6
```

```bash
flutter pub get
```

插件通过 `dartPluginClass` 自动注册，业务代码直接使用 `shared_preferences` 的 API 即可。

同步 API：

```dart
import 'package:shared_preferences/shared_preferences.dart';

final SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('key', 'value');
final String? value = prefs.getString('key');
```

异步 API：

```dart
import 'package:shared_preferences/shared_preferences.dart';

final SharedPreferencesAsync prefs = SharedPreferencesAsync();
await prefs.setString('key', 'value');
final String? value = await prefs.getString('key');
```

异步 API 的鸿蒙后端选项：

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_harmonyos/shared_preferences_harmonyos.dart';

// options 需要在构造 SharedPreferencesAsync 时传入。
// 默认使用 DataStore：
const options = SharedPreferencesAsyncOhosOptions();
// 或使用传统 SharedPreferences 后端：
// const options = SharedPreferencesAsyncOhosOptions(
//   backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
// );

final SharedPreferencesAsync prefs = SharedPreferencesAsync(options: options);
await prefs.setString('key', 'value');
```

## 鸿蒙平台限制

- 同步 API 与异步 API 使用不同的存储后端，请勿混用同一份数据。
- 大数据量的 `getAll` 单次跨线程传递可能较慢，建议通过 allowList 控制读取范围。
- `clear()` 默认只清理 `flutter.` 前缀的数据；异步 API 的清理范围由后端决定。

## 兼容版本

- 对应上游 Flutter 插件版本：`shared_preferences 2.5.6`
- 平台接口依赖：`shared_preferences_platform_interface: ^2.4.0`
- 运行环境要求：Flutter `>=3.41.0`、Dart `>=3.11.0`
