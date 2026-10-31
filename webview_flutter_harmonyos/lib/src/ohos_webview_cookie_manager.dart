// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:webview_flutter_harmonyos/src/ohos_webview.dart';
import 'package:webview_flutter_harmonyos/src/ohos_webview_controller.dart';

@immutable
class OhosWebViewCookieManagerCreationParams extends PlatformWebViewCookieManagerCreationParams {
  const OhosWebViewCookieManagerCreationParams._(
    // ignore: avoid_unused_constructor_parameters
    PlatformWebViewCookieManagerCreationParams params,
  ) : super();

  factory OhosWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return OhosWebViewCookieManagerCreationParams._(params);
  }
}

class OhosWebViewCookieManager extends PlatformWebViewCookieManager {
  OhosWebViewCookieManager(PlatformWebViewCookieManagerCreationParams params, {CookieManager? cookieManager})
    : _cookieManager = cookieManager ?? CookieManager.instance,
      super.implementation(
        params is OhosWebViewCookieManagerCreationParams
            ? params
            : OhosWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(params),
      );

  final CookieManager _cookieManager;

  @override
  Future<bool> clearCookies() {
    return _cookieManager.removeAllCookies();
  }

  @override
  Future<List<WebViewCookie>> getCookies(Uri url) async {
    final String? cookies = await _cookieManager.getCookies(url.toString());
    if (cookies == null || cookies.isEmpty) {
      return <WebViewCookie>[];
    }

    final List<WebViewCookie> webViewCookies = <WebViewCookie>[];
    for (final String cookie in cookies.split('; ')) {
      final int separator = cookie.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      webViewCookies.add(
        WebViewCookie(
          name: cookie.substring(0, separator),
          value: cookie.substring(separator + 1),
          domain: url.toString(),
        ),
      );
    }
    return webViewCookies;
  }

  @override
  Future<void> setCookie(WebViewCookie cookie) {
    if (!_isValidPath(cookie.path)) {
      throw ArgumentError('The path property for the provided cookie was not given a legal value.');
    }
    return _cookieManager.setCookie(
      cookie.domain,
      '${Uri.encodeComponent(cookie.name)}=${Uri.encodeComponent(cookie.value)}; path=${cookie.path}',
    );
  }

  bool _isValidPath(String path) {
    for (final int char in path.codeUnits) {
      if ((char < 0x20 || char > 0x3A) && (char < 0x3C || char > 0x7E)) {
        return false;
      }
    }
    return true;
  }

  Future<void> setAcceptThirdPartyCookies(OhosWebViewController controller, bool accept) {
    // ignore: invalid_use_of_visible_for_testing_member
    final WebView webView = WebView.api.instanceManager.getInstanceWithWeakReference(controller.webViewIdentifier)!;
    return _cookieManager.setAcceptThirdPartyCookies(webView, accept);
  }
}
