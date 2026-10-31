/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:url_launcher_harmonyos/src/messages.g.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

export 'package:url_launcher_harmonyos/src/messages.g.dart';
export 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class UrlLauncherOhos extends UrlLauncherPlatform {
  UrlLauncherOhos({@visibleForTesting UrlLauncherApi? api}) : _hostApi = api ?? UrlLauncherApi();

  final UrlLauncherApi _hostApi;

  static void registerWith() {
    UrlLauncherPlatform.instance = UrlLauncherOhos();
  }

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> canLaunch(String url) async {
    final bool canLaunchSpecificUrl = await _hostApi.canLaunchUrl(url);
    if (!canLaunchSpecificUrl) {
      final String scheme = _getUrlScheme(url);
      // 自定义应用处理网页链接时 canLaunch 可能返回 false，且调用方无法看到具体处理器；
      // 这里用同 scheme 的通用网页试探一次，能打开说明系统存在浏览器，也就存在原链接的处理器。
      if (scheme == 'http' || scheme == 'https') {
        return _hostApi.canLaunchUrl('$scheme://flutter.dev');
      }
    }
    return canLaunchSpecificUrl;
  }

  @override
  Future<void> closeWebView() {
    return _hostApi.closeWebView();
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    final bool inApp;
    switch (options.mode) {
      case PreferredLaunchMode.inAppWebView:
      case PreferredLaunchMode.inAppBrowserView:
        inApp = true;
      case PreferredLaunchMode.externalApplication:
      case PreferredLaunchMode.externalNonBrowserApplication:
        inApp = false;
      case PreferredLaunchMode.platformDefault:
        inApp = url.startsWith('http:') || url.startsWith('https:');
    }

    final bool succeeded;
    if (inApp) {
      succeeded = await _hostApi.openUrlInWebView(
        url,
        WebViewOptions(
          enableJavaScript: options.webViewConfiguration.enableJavaScript,
          enableDomStorage: options.webViewConfiguration.enableDomStorage,
          headers: options.webViewConfiguration.headers,
        ),
        BrowserOptions(showTitle: options.browserConfiguration.showTitle),
      );
    } else {
      succeeded = await _hostApi.launchUrl(url, options.webViewConfiguration.headers);
    }

    if (!succeeded) {
      throw PlatformException(code: 'ACTIVITY_NOT_FOUND', message: 'No Activity found to handle intent { $url }');
    }

    return succeeded;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async {
    switch (mode) {
      case PreferredLaunchMode.platformDefault:
      case PreferredLaunchMode.inAppWebView:
      case PreferredLaunchMode.inAppBrowserView:
      case PreferredLaunchMode.externalApplication:
        return true;
      case PreferredLaunchMode.externalNonBrowserApplication:
        return false;
    }
  }

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async {
    return mode == PreferredLaunchMode.inAppWebView || mode == PreferredLaunchMode.inAppBrowserView;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    return launchUrl(
      url,
      LaunchOptions(
        mode: useWebView ? PreferredLaunchMode.inAppWebView : PreferredLaunchMode.externalApplication,
        webViewConfiguration: InAppWebViewConfiguration(
          enableDomStorage: enableDomStorage,
          enableJavaScript: enableJavaScript,
          headers: headers,
        ),
      ),
    );
  }

  // 手动截取 scheme 而不使用 Uri，以便兼容并非合法 URL 的字符串，因为鸿蒙对可启动链接的校验很宽松。
  String _getUrlScheme(String url) {
    final int schemeEnd = url.indexOf(':');
    if (schemeEnd == -1) {
      return '';
    }
    return url.substring(0, schemeEnd);
  }
}
