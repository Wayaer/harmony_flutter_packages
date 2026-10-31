# in_app_purchase_ohos

`in_app_purchase` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，基于鸿蒙 IAP Kit（AppGallery Connect）提供应用内购买能力。

- 当前版本：`3.2.3`
- 对应 Flutter 包：[in_app_purchase 3.2.3](https://pub.dev/packages/in_app_purchase/versions/3.2.3)

## 安装与使用

```yaml
dependencies:
  in_app_purchase: ^3.2.3
  in_app_purchase_ohos: ^3.2.3
```

```bash
flutter pub get
```

`in_app_purchase_ohos` 是 `in_app_purchase` 的联邦实现，业务代码可以直接使用 `in_app_purchase` 的 API。直接使用本插件时，需要在应用启动时注册平台实现：

```dart
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InAppPurchaseOhosPlatform.registerPlatform();
  runApp(MyApp());
}
```

```dart
final InAppPurchaseOhosPlatform iap = InAppPurchasePlatform.instance as InAppPurchaseOhosPlatform;

final bool available = await iap.isAvailable();
iap.purchaseStream.listen((List<PurchaseDetails> purchases) {
  for (final purchase in purchases) {
    // 处理 purchased / restored / pending / error / canceled
  }
});
final ProductDetailsResponse response = await iap.queryProductDetails(<String>{'product_id'});
await iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
if (purchase.pendingCompletePurchase) {
  await iap.completePurchase(purchase);
}
```

## 鸿蒙平台限制

- 应用需在 AppGallery Connect 完成注册并配置应用内购买商品。
- 需要配置有效的签名证书与 `client_id`，否则 IAP Kit 无法正常拉起支付。
- 需要在真机或具备 AppGallery 服务的设备上测试。
- 业务应用需要声明 `ohos.permission.INTERNET`。

## 兼容版本

- 对应上游 Flutter 插件版本：`in_app_purchase 3.2.3`
- 平台接口依赖：`in_app_purchase_platform_interface: ^1.4.0`
