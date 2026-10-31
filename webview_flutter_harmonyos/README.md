# webview_flutter_harmonyos

`webview_flutter` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `webview_flutter 4.14.1`。

## 安装与使用

```yaml
dependencies:
  webview_flutter: ^4.14.1
  webview_flutter_harmonyos: ^4.14.1
```

```bash
flutter pub get
```

插件通过 `dartPluginClass` 自动注册，业务代码直接使用 `webview_flutter` 的 API 即可。

```dart
import 'package:webview_flutter/webview_flutter.dart';

final WebViewController controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(
    NavigationDelegate(
      onPageFinished: (String url) {},
      onNavigationRequest: (NavigationRequest request) {
        return NavigationDecision.navigate;
      },
    ),
  )
  ..loadRequest(Uri.parse('https://flutter.dev'));

WebViewWidget(controller: controller);
```

## 鸿蒙平台限制

- 加载网络页面需要 `ohos.permission.INTERNET`。
- WebView 渲染依赖系统 `Web` 组件，自定义 Scheme 拦截等部分高级能力受系统限制。
- SSL 错误通过 `OhosSslAuthError` 传递，业务需显式处理证书错误。
- 文件选择、下载、权限请求等回调需要业务自行实现对应 UI。
- 支付请求 API 仅在支持的设备与系统版本上可用。
- Legacy API 已不推荐使用，新项目请使用 `PlatformWebViewController` 系列 API。

## 兼容版本

- 对应上游 Flutter 插件版本：`webview_flutter 4.14.1`
- 平台接口依赖：`webview_flutter_platform_interface: ^2.15.1`
- 运行环境要求：Flutter `>=3.38.0`、Dart `>=3.10.0`
