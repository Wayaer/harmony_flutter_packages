// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import 'package:webview_flutter_harmonyos/src/ohos_webview.dart';
import 'package:webview_flutter_harmonyos/src/instance_manager.dart';
import 'package:webview_flutter_harmonyos/src/legacy/webview_ohos_widget.dart';

class OhosWebView implements WebViewPlatform {
  OhosWebView({@visibleForTesting InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  @protected
  final InstanceManager instanceManager;

  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
    required JavascriptChannelRegistry javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) {
    return WebViewOhosWidget(
      creationParams: creationParams,
      callbacksHandler: webViewPlatformCallbacksHandler,
      javascriptChannelRegistry: javascriptChannelRegistry,
      onBuildWidget: (WebViewOhosPlatformController controller) {
        return GestureDetector(
          // 拦截长按，规避 Ohos 文本选择弹窗不响应触摸事件的问题，相关 issue 修复后可移除
          onLongPress: () {},
          excludeFromSemantics: true,
          child: OhosView(
            viewType: 'plugins.flutter.io/webview',
            onPlatformViewCreated: (int id) {
              if (onWebViewPlatformCreated != null) {
                onWebViewPlatformCreated(controller);
              }
            },
            gestureRecognizers: gestureRecognizers,
            layoutDirection: Directionality.maybeOf(context) ?? TextDirection.rtl,
            creationParams: instanceManager.getIdentifier(controller.webView),
            creationParamsCodec: const StandardMessageCodec(),
          ),
        );
      },
    );
  }

  @override
  Future<bool> clearCookies() {
    if (WebViewCookieManagerPlatform.instance == null) {
      throw Exception(
        'Could not clear cookies as no implementation for WebViewCookieManagerPlatform has been registered.',
      );
    }
    return WebViewCookieManagerPlatform.instance!.clearCookies();
  }
}
