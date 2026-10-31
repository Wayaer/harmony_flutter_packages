# url_launcher_harmonyos

`url_launcher` 的鸿蒙（OpenHarmony / HarmonyOS）平台实现，兼容 Flutter 插件 `url_launcher 6.3.3`。

## 安装与使用

```yaml
dependencies:
  url_launcher: ^6.3.3
  url_launcher_harmonyos: ^6.3.3
```

```bash
flutter pub get
```

插件通过 `dartPluginClass` 自动注册，业务代码直接使用 `url_launcher` 的 API 即可。

```dart
import 'package:url_launcher/url_launcher.dart';

final Uri uri = Uri.parse('https://flutter.dev');
if (await canLaunchUrl(uri)) {
  await launchUrl(uri);
}

await launchUrl(
  uri,
  mode: LaunchMode.inAppWebView,
  webViewConfiguration: const WebViewConfiguration(
    enableJavaScript: true,
    enableDomStorage: true,
    // 必须提供 harmony_browser_page，值为宿主工程中已注册的页面路由
    headers: <String, String>{
      'harmony_browser_page': 'pages/LaunchInAppPage',
      'X-Test': 'value',
    },
  ),
  browserConfiguration: const BrowserConfiguration(showTitle: true),
);

await launchUrl(uri, mode: LaunchMode.externalApplication);
await closeInAppWebView();
```

## 鸿蒙平台限制

- `LaunchMode.externalNonBrowserApplication` 不支持，`supportsMode` 返回 `false`。
- 应用内 WebView（`LaunchMode.inAppWebView` / `inAppBrowserView`）**必须**在 `headers` 中传入 `harmony_browser_page`，值为宿主 ohos 工程中已注册的页面路由；未传时 `launchUrl` 返回 `false`。
- 自定义 headers 依赖该 WebView 页面解析，未注册页面时 headers 不生效。
- 打开网页链接需要 `ohos.permission.INTERNET`。
- 部分三方应用未声明可被外部调起的 Want，`canLaunchUrl` 会返回 `false`。
- 对 `tel`/`http`/`https`/`mailto`/`sms`/`file`/`appgallery` 前缀，`canLaunchUrl` 仅按协议判断并返回 `true`，不校验目标应用是否真的存在；其它协议才使用 `bundleManager.canOpenLink`。

## 兼容版本

- 对应上游 Flutter 插件版本：`url_launcher 6.3.3`
- 平台接口依赖：`url_launcher_platform_interface: ^2.3.2`
- 运行环境要求：Flutter `>=3.41.0`、Dart `>=3.11.0`
