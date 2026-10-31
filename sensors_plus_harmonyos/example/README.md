# sensors_plus_harmonyos_example

`sensors_plus_harmonyos` 的鸿蒙示例程序，仅包含 ohos 平台，通过 `pubspec_overrides.yaml` 引用本地插件。

## 运行

```bash
flutter pub get
flutter run -d <鸿蒙设备>
```

示例实时展示加速度计与陀螺仪数据，并在传感器不可用时给出提示。
