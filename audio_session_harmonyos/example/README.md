# audio_session_harmonyos_example

`audio_session_harmonyos` 的鸿蒙示例程序，仅包含 ohos 平台，通过 `pubspec_overrides.yaml` 引用本地插件。

## 运行

```bash
flutter pub get
flutter run -d <鸿蒙设备>
```

## 功能

- 配置并激活语音会话（`AudioSessionConfiguration.speech()`）
- 配置并激活音乐会话（`AudioSessionConfiguration.music()`）
- 监听音频中断事件
- 取消激活音频会话
