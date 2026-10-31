# image_picker_harmonyos_example

`image_picker_harmonyos` 的鸿蒙示例程序，仅包含 ohos 平台，通过 `pubspec_overrides.yaml` 引用本地插件。

## 运行

```bash
flutter pub get
flutter run -d <鸿蒙设备>
```

## 功能

- 从相册选择图片
- 调用相机拍照
- 展示已选图片

相机功能需要在 `entry/src/main/module.json5` 中声明 `ohos.permission.CAMERA`（示例已配置）。
