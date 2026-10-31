# in_app_purchase_ohos_example

`in_app_purchase_ohos` 的鸿蒙示例程序，仅包含 ohos 平台，通过 `pubspec_overrides.yaml` 引用本地插件。

## 运行

```bash
flutter pub get
flutter run -d <鸿蒙设备>
```

## 说明

- 示例需要配置 AppGallery Connect 商品与签名，否则支付无法真实完成。
- 商品 ID 见 `lib/main.dart` 中的 `productIds`，可按实际配置调整。
- 示例展示商品查询、购买、恢复购买与购买结果回调。
