# image_picker_harmonyos

`image_picker` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `image_picker 1.2.4`。

## 安装与使用

```yaml
dependencies:
  image_picker: ^1.2.4
  image_picker_harmonyos: ^1.2.4
```

```bash
flutter pub get
```

插件通过 `dartPluginClass` 自动注册，业务代码直接使用 `image_picker` 的 API 即可。

```dart
import 'package:image_picker/image_picker.dart';

final ImagePicker picker = ImagePicker();

final XFile? image = await picker.pickImage(source: ImageSource.gallery);
final List<XFile> images = await picker.pickMultiImage(limit: 3);
final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
final List<XFile> media = await picker.pickMultipleMedia(limit: 3);
```

选择器模式：

```dart
import 'package:image_picker_harmonyos/image_picker_harmonyos.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

final ImagePickerPlatform picker = ImagePickerPlatform.instance;
if (picker is ImagePickerOhos) {
  picker.useOhosPhotoPicker = true; // 该开关目前保留：true/false 均使用系统 PhotoPicker
}
```

## 鸿蒙平台限制

- 相机拍照 / 录像需要声明 `ohos.permission.CAMERA`，未声明时相关接口会返回权限错误。
- `useOhosPhotoPicker` 暂未接入文件选择器分支，两种取值都使用系统 PhotoPicker。
- 多选数量受系统选择器上限约束，超大数量可能被系统截断。
- 图片压缩、EXIF 信息复制在部分机型上受系统能力限制。

## 兼容版本

- 对应上游 Flutter 插件版本：`image_picker 1.2.4`
- 平台接口依赖：`image_picker_platform_interface: ^2.11.0`
- 运行环境要求：Flutter `>=3.41.0`、Dart `>=3.11.0`
