// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import 'package:webview_flutter_harmonyos/src/legacy/webview_ohos.dart';
import 'package:webview_flutter_harmonyos/src/legacy/webview_ohos_widget.dart';

class SurfaceOhosWebView extends OhosWebView {
  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required JavascriptChannelRegistry javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
  }) {
    return WebViewOhosWidget(
      creationParams: creationParams,
      callbacksHandler: webViewPlatformCallbacksHandler,
      javascriptChannelRegistry: javascriptChannelRegistry,
      onBuildWidget: (WebViewOhosPlatformController controller) {
        return PlatformViewLink(
          viewType: 'plugins.flutter.io/webview',
          surfaceFactory: (BuildContext context, PlatformViewController controller) {
            return OhosViewSurface(
              controller: controller as OhosViewController,
              gestureRecognizers: gestureRecognizers ?? const <Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            final Color? backgroundColor = creationParams.backgroundColor;
            return _createViewController(
                // 部分 Ohos 设备上非透视背景会出现渲染异常，因此背景非全不透明时改用 Hybrid Composition
                hybridComposition: backgroundColor != null && backgroundColor.a < 1.0,
                id: params.id,
                viewType: 'plugins.flutter.io/webview',
                // WebView 内容不跟随 Ohos 视图的布局方向，这里显式设置，避免依赖环境的 Directionality
                layoutDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
                webViewIdentifier: instanceManager.getIdentifier(controller.webView)!,
              )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener((int id) {
                if (onWebViewPlatformCreated != null) {
                  onWebViewPlatformCreated(controller);
                }
              })
              ..create();
          },
        );
      },
    );
  }

  OhosViewController _createViewController({
    required bool hybridComposition,
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    required int webViewIdentifier,
  }) {
    if (hybridComposition) {
      return PlatformViewsService.initExpensiveOhosView(
        id: id,
        viewType: viewType,
        layoutDirection: layoutDirection,
        creationParams: webViewIdentifier,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return PlatformViewsService.initSurfaceOhosView(
      id: id,
      viewType: viewType,
      layoutDirection: layoutDirection,
      creationParams: webViewIdentifier,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
