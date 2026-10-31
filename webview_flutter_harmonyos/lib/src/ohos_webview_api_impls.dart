// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show unawaited;
import 'dart:ui';

import 'package:flutter/services.dart' show BinaryMessenger, Uint8List;

import 'package:webview_flutter_harmonyos/src/instance_manager.dart';
import 'package:webview_flutter_harmonyos/src/ohos_webview.dart';
import 'package:webview_flutter_harmonyos/src/ohos_webview.g.dart';

export 'ohos_webview.g.dart' show ConsoleMessage, ConsoleMessageLevel, FileChooserMode;

WebResourceRequest _toWebResourceRequest(WebResourceRequestData data) {
  return WebResourceRequest(
    url: data.url,
    isForMainFrame: data.isForMainFrame,
    isRedirect: data.isRedirect,
    hasGesture: data.hasGesture,
    method: data.method,
    requestHeaders: data.requestHeaders.cast<String, String>(),
  );
}

WebResourceError _toWebResourceError(WebResourceErrorData data) {
  return WebResourceError(errorCode: data.errorCode, description: data.description);
}

class OhosWebViewFlutterApis {
  OhosWebViewFlutterApis({
    OhosObjectFlutterApiImpl? ohosObjectFlutterApi,
    DownloadListenerFlutterApiImpl? downloadListenerFlutterApi,
    WebViewClientFlutterApiImpl? webViewClientFlutterApi,
    WebChromeClientFlutterApiImpl? webChromeClientFlutterApi,
    JavaScriptChannelFlutterApiImpl? javaScriptChannelFlutterApi,
    FileChooserParamsFlutterApiImpl? fileChooserParamsFlutterApi,
    GeolocationPermissionsCallbackFlutterApiImpl? geolocationPermissionsCallbackFlutterApi,
    WebViewFlutterApiImpl? webViewFlutterApi,
    PermissionRequestFlutterApiImpl? permissionRequestFlutterApi,
    CustomViewCallbackFlutterApiImpl? customViewCallbackFlutterApi,
    ViewFlutterApiImpl? viewFlutterApi,
    HttpAuthHandlerFlutterApiImpl? httpAuthHandlerFlutterApi,
    SslErrorHandlerFlutterApiImpl? sslErrorHandlerFlutterApi,
  }) {
    this.ohosObjectFlutterApi = ohosObjectFlutterApi ?? OhosObjectFlutterApiImpl();
    this.downloadListenerFlutterApi = downloadListenerFlutterApi ?? DownloadListenerFlutterApiImpl();
    this.webViewClientFlutterApi = webViewClientFlutterApi ?? WebViewClientFlutterApiImpl();
    this.webChromeClientFlutterApi = webChromeClientFlutterApi ?? WebChromeClientFlutterApiImpl();
    this.javaScriptChannelFlutterApi = javaScriptChannelFlutterApi ?? JavaScriptChannelFlutterApiImpl();
    this.fileChooserParamsFlutterApi = fileChooserParamsFlutterApi ?? FileChooserParamsFlutterApiImpl();
    this.geolocationPermissionsCallbackFlutterApi =
        geolocationPermissionsCallbackFlutterApi ?? GeolocationPermissionsCallbackFlutterApiImpl();
    this.webViewFlutterApi = webViewFlutterApi ?? WebViewFlutterApiImpl();
    this.permissionRequestFlutterApi = permissionRequestFlutterApi ?? PermissionRequestFlutterApiImpl();
    this.customViewCallbackFlutterApi = customViewCallbackFlutterApi ?? CustomViewCallbackFlutterApiImpl();
    this.viewFlutterApi = viewFlutterApi ?? ViewFlutterApiImpl();
    this.httpAuthHandlerFlutterApi = httpAuthHandlerFlutterApi ?? HttpAuthHandlerFlutterApiImpl();
    this.sslErrorHandlerFlutterApi = sslErrorHandlerFlutterApi ?? SslErrorHandlerFlutterApiImpl();
  }

  static bool _haveBeenSetUp = false;

  static OhosWebViewFlutterApis instance = OhosWebViewFlutterApis();

  late final OhosObjectFlutterApi ohosObjectFlutterApi;

  late final DownloadListenerFlutterApiImpl downloadListenerFlutterApi;

  late final WebViewClientFlutterApiImpl webViewClientFlutterApi;

  late final WebChromeClientFlutterApiImpl webChromeClientFlutterApi;

  late final JavaScriptChannelFlutterApiImpl javaScriptChannelFlutterApi;

  late final FileChooserParamsFlutterApiImpl fileChooserParamsFlutterApi;

  late final GeolocationPermissionsCallbackFlutterApiImpl geolocationPermissionsCallbackFlutterApi;

  late final WebViewFlutterApiImpl webViewFlutterApi;

  late final PermissionRequestFlutterApiImpl permissionRequestFlutterApi;

  late final CustomViewCallbackFlutterApiImpl customViewCallbackFlutterApi;

  late final ViewFlutterApiImpl viewFlutterApi;

  late final HttpAuthHandlerFlutterApiImpl httpAuthHandlerFlutterApi;

  late final SslErrorHandlerFlutterApiImpl sslErrorHandlerFlutterApi;

  void ensureSetUp() {
    if (!_haveBeenSetUp) {
      OhosObjectFlutterApi.setup(ohosObjectFlutterApi);
      DownloadListenerFlutterApi.setup(downloadListenerFlutterApi);
      WebViewClientFlutterApi.setup(webViewClientFlutterApi);
      WebChromeClientFlutterApi.setup(webChromeClientFlutterApi);
      JavaScriptChannelFlutterApi.setup(javaScriptChannelFlutterApi);
      FileChooserParamsFlutterApi.setup(fileChooserParamsFlutterApi);
      GeolocationPermissionsCallbackFlutterApi.setup(geolocationPermissionsCallbackFlutterApi);
      WebViewFlutterApi.setup(webViewFlutterApi);
      PermissionRequestFlutterApi.setup(permissionRequestFlutterApi);
      CustomViewCallbackFlutterApi.setup(customViewCallbackFlutterApi);
      ViewFlutterApi.setup(viewFlutterApi);
      HttpAuthHandlerFlutterApi.setup(httpAuthHandlerFlutterApi);
      SslErrorHandlerFlutterApi.setup(sslErrorHandlerFlutterApi);
      _haveBeenSetUp = true;
    }
  }
}

class OhosObjectHostApiImpl extends OhosObjectHostApi {
  OhosObjectHostApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager,
      super(binaryMessenger: binaryMessenger);

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;
}

class OhosObjectFlutterApiImpl implements OhosObjectFlutterApi {
  OhosObjectFlutterApiImpl({InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  @override
  void dispose(int identifier) {
    instanceManager.remove(identifier);
  }
}

class WebViewHostApiImpl extends WebViewHostApi {
  WebViewHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  Future<void> createFromInstance(WebView instance) {
    return create(instanceManager.addDartCreatedInstance(instance));
  }

  Future<void> loadDataFromInstance(WebView instance, String data, String? mimeType, String? encoding) {
    return loadData(instanceManager.getIdentifier(instance)!, data, mimeType, encoding);
  }

  Future<void> loadDataWithBaseUrlFromInstance(
    WebView instance,
    String? baseUrl,
    String data,
    String? mimeType,
    String? encoding,
    String? historyUrl,
  ) {
    return loadDataWithBaseUrl(instanceManager.getIdentifier(instance)!, baseUrl, data, mimeType, encoding, historyUrl);
  }

  Future<void> loadUrlFromInstance(WebView instance, String url, Map<String, String> headers) {
    return loadUrl(instanceManager.getIdentifier(instance)!, url, headers);
  }

  Future<void> postUrlFromInstance(WebView instance, String url, Uint8List data) {
    return postUrl(instanceManager.getIdentifier(instance)!, url, data);
  }

  Future<String?> getUrlFromInstance(WebView instance) {
    return getUrl(instanceManager.getIdentifier(instance)!);
  }

  Future<bool> canGoBackFromInstance(WebView instance) {
    return canGoBack(instanceManager.getIdentifier(instance)!);
  }

  Future<bool> canGoForwardFromInstance(WebView instance) {
    return canGoForward(instanceManager.getIdentifier(instance)!);
  }

  Future<void> goBackFromInstance(WebView instance) {
    return goBack(instanceManager.getIdentifier(instance)!);
  }

  Future<void> goForwardFromInstance(WebView instance) {
    return goForward(instanceManager.getIdentifier(instance)!);
  }

  Future<void> reloadFromInstance(WebView instance) {
    return reload(instanceManager.getIdentifier(instance)!);
  }

  Future<void> clearCacheFromInstance(WebView instance, bool includeDiskFiles) {
    return clearCache(instanceManager.getIdentifier(instance)!, includeDiskFiles);
  }

  Future<String?> evaluateJavascriptFromInstance(WebView instance, String javascriptString) {
    return evaluateJavascript(instanceManager.getIdentifier(instance)!, javascriptString);
  }

  Future<String?> getTitleFromInstance(WebView instance) {
    return getTitle(instanceManager.getIdentifier(instance)!);
  }

  Future<void> scrollToFromInstance(WebView instance, int x, int y) {
    return scrollTo(instanceManager.getIdentifier(instance)!, x, y);
  }

  Future<void> scrollByFromInstance(WebView instance, int x, int y) {
    return scrollBy(instanceManager.getIdentifier(instance)!, x, y);
  }

  Future<int> getScrollXFromInstance(WebView instance) {
    return getScrollX(instanceManager.getIdentifier(instance)!);
  }

  Future<int> getScrollYFromInstance(WebView instance) {
    return getScrollY(instanceManager.getIdentifier(instance)!);
  }

  Future<Offset> getScrollPositionFromInstance(WebView instance) async {
    final WebViewPoint position = await getScrollPosition(instanceManager.getIdentifier(instance)!);
    return Offset(position.x.toDouble(), position.y.toDouble());
  }

  Future<void> setWebViewClientFromInstance(WebView instance, WebViewClient webViewClient) {
    return setWebViewClient(instanceManager.getIdentifier(instance)!, instanceManager.getIdentifier(webViewClient)!);
  }

  Future<void> addJavaScriptChannelFromInstance(WebView instance, JavaScriptChannel javaScriptChannel) {
    return addJavaScriptChannel(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(javaScriptChannel)!,
    );
  }

  Future<void> removeJavaScriptChannelFromInstance(WebView instance, JavaScriptChannel javaScriptChannel) {
    return removeJavaScriptChannel(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(javaScriptChannel)!,
    );
  }

  Future<void> setDownloadListenerFromInstance(WebView instance, DownloadListener? listener) {
    return setDownloadListener(
      instanceManager.getIdentifier(instance)!,
      listener != null ? instanceManager.getIdentifier(listener) : null,
    );
  }

  Future<void> setWebChromeClientFromInstance(WebView instance, WebChromeClient? client) {
    return setWebChromeClient(
      instanceManager.getIdentifier(instance)!,
      client != null ? instanceManager.getIdentifier(client) : null,
    );
  }
}

class WebViewFlutterApiImpl implements WebViewFlutterApi {
  WebViewFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(int identifier) {
    instanceManager.addHostCreatedInstance(WebView.detached(), identifier);
  }

  @override
  void onScrollChanged(int webViewInstanceId, int left, int top, int oldLeft, int oldTop) {
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    webViewInstance!.onScrollChanged?.call(left, top, oldLeft, oldTop);
  }
}

class WebSettingsHostApiImpl extends WebSettingsHostApi {
  WebSettingsHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  Future<void> createFromInstance(WebSettings instance, WebView webView) {
    return create(instanceManager.addDartCreatedInstance(instance), instanceManager.getIdentifier(webView)!);
  }

  Future<void> setDomStorageEnabledFromInstance(WebSettings instance, bool flag) {
    return setDomStorageEnabled(instanceManager.getIdentifier(instance)!, flag);
  }

  Future<void> setJavaScriptCanOpenWindowsAutomaticallyFromInstance(WebSettings instance, bool flag) {
    return setJavaScriptCanOpenWindowsAutomatically(instanceManager.getIdentifier(instance)!, flag);
  }

  Future<void> setSupportMultipleWindowsFromInstance(WebSettings instance, bool support) {
    return setSupportMultipleWindows(instanceManager.getIdentifier(instance)!, support);
  }

  Future<void> setBackgroundColorFromInstance(WebSettings instance, int color) {
    return setBackgroundColor(instanceManager.getIdentifier(instance)!, color);
  }

  Future<void> setJavaScriptEnabledFromInstance(WebSettings instance, bool flag) {
    return setJavaScriptEnabled(instanceManager.getIdentifier(instance)!, flag);
  }

  Future<void> setUserAgentStringFromInstance(WebSettings instance, String? userAgentString) {
    return setUserAgentString(instanceManager.getIdentifier(instance)!, userAgentString);
  }

  Future<void> setMediaPlaybackRequiresUserGestureFromInstance(WebSettings instance, bool require) {
    return setMediaPlaybackRequiresUserGesture(instanceManager.getIdentifier(instance)!, require);
  }

  Future<void> setSupportZoomFromInstance(WebSettings instance, bool support) {
    return setSupportZoom(instanceManager.getIdentifier(instance)!, support);
  }

  Future<void> setSetTextZoomFromInstance(WebSettings instance, int textZoom) {
    return setTextZoom(instanceManager.getIdentifier(instance)!, textZoom);
  }

  Future<void> setLoadWithOverviewModeFromInstance(WebSettings instance, bool overview) {
    return setLoadWithOverviewMode(instanceManager.getIdentifier(instance)!, overview);
  }

  Future<void> setUseWideViewPortFromInstance(WebSettings instance, bool use) {
    return setUseWideViewPort(instanceManager.getIdentifier(instance)!, use);
  }

  Future<void> setDisplayZoomControlsFromInstance(WebSettings instance, bool enabled) {
    return setDisplayZoomControls(instanceManager.getIdentifier(instance)!, enabled);
  }

  Future<void> setBuiltInZoomControlsFromInstance(WebSettings instance, bool enabled) {
    return setBuiltInZoomControls(instanceManager.getIdentifier(instance)!, enabled);
  }

  Future<void> setAllowFileAccessFromInstance(WebSettings instance, bool enabled) {
    return setAllowFileAccess(instanceManager.getIdentifier(instance)!, enabled);
  }

  Future<String> getUserAgentStringFromInstance(WebSettings instance) {
    return getUserAgentString(instanceManager.getIdentifier(instance)!);
  }

  Future<void> setAllowFullScreenRotateInstance(WebSettings instance, bool enabled) {
    return setAllowFullScreenRotate(instanceManager.getIdentifier(instance)!, enabled);
  }

  Future<void> setPaymentRequestEnabledFromInstance(WebSettings instance, bool enabled) {
    return setPaymentRequestEnabled(instanceManager.getIdentifier(instance)!, enabled);
  }

  Future<void> setMixedContentModeFromInstance(WebSettings instance, MixedContentMode mode) {
    return setMixedContentMode(instanceManager.getIdentifier(instance)!, mode.index);
  }

  Future<void> setOverScrollModeFromInstance(WebSettings instance, OverScrollMode mode) {
    return setOverScrollMode(instanceManager.getIdentifier(instance)!, mode.index);
  }

  Future<void> setVerticalScrollBarAccessEnabledFromInstance(WebSettings instance, bool enabled) {
    return setVerticalScrollBarAccessEnabled(instanceManager.getIdentifier(instance)!, enabled);
  }

  Future<void> setHorizontalScrollBarAccessEnabledFromInstance(WebSettings instance, bool enabled) {
    return setHorizontalScrollBarAccessEnabled(instanceManager.getIdentifier(instance)!, enabled);
  }
}

class JavaScriptChannelHostApiImpl extends JavaScriptChannelHostApi {
  JavaScriptChannelHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  Future<void> createFromInstance(JavaScriptChannel instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      await create(identifier, instance.channelName);
    }
  }
}

class JavaScriptChannelFlutterApiImpl extends JavaScriptChannelFlutterApi {
  JavaScriptChannelFlutterApiImpl({InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  @override
  void postMessage(int instanceId, String message) {
    final JavaScriptChannel? instance = instanceManager.getInstanceWithWeakReference(instanceId) as JavaScriptChannel?;
    assert(instance != null, 'InstanceManager does not contain a JavaScriptChannel with instanceId: $instanceId');
    instance!.postMessage(message);
  }
}

class WebViewClientHostApiImpl extends WebViewClientHostApi {
  WebViewClientHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  Future<void> createFromInstance(WebViewClient instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }

  Future<void> setShouldOverrideUrlLoadingReturnValueFromInstance(WebViewClient instance, bool value) {
    return setSynchronousReturnValueForShouldOverrideUrlLoading(instanceManager.getIdentifier(instance)!, value);
  }
}

class WebViewClientFlutterApiImpl extends WebViewClientFlutterApi {
  WebViewClientFlutterApiImpl({InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  @override
  void onPageFinished(int instanceId, int webViewInstanceId, String url) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.onPageFinished != null) {
      instance.onPageFinished!(webViewInstance!, url);
    }
  }

  @override
  void onPageStarted(int instanceId, int webViewInstanceId, String url) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.onPageStarted != null) {
      instance.onPageStarted!(webViewInstance!, url);
    }
  }

  @override
  void onReceivedError(int instanceId, int webViewInstanceId, int errorCode, String description, String failingUrl) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    // ignore: deprecated_member_use_from_same_package
    if (instance!.onReceivedError != null) {
      instance.onReceivedError!(webViewInstance!, errorCode, description, failingUrl);
    }
  }

  @override
  void onReceivedRequestError(
    int instanceId,
    int webViewInstanceId,
    WebResourceRequestData request,
    WebResourceErrorData error,
  ) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.onReceivedRequestError != null) {
      instance.onReceivedRequestError!(webViewInstance!, _toWebResourceRequest(request), _toWebResourceError(error));
    }
  }

  @override
  void requestLoading(int instanceId, int webViewInstanceId, WebResourceRequestData request) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.requestLoading != null) {
      instance.requestLoading!(webViewInstance!, _toWebResourceRequest(request));
    }
  }

  @override
  void urlLoading(int instanceId, int webViewInstanceId, String url) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.urlLoading != null) {
      instance.urlLoading!(webViewInstance!, url);
    }
  }

  @override
  void doUpdateVisitedHistory(int instanceId, int webViewInstanceId, String url, bool isReload) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.doUpdateVisitedHistory != null) {
      instance.doUpdateVisitedHistory!(webViewInstance!, url, isReload);
    }
  }

  @override
  void onReceivedHttpAuthRequest(
    int instanceId,
    int webViewInstanceId,
    int httpAuthHandlerInstanceId,
    String host,
    String realm,
  ) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    final HttpAuthHandler? httpAuthHandlerInstance =
        instanceManager.getInstanceWithWeakReference(httpAuthHandlerInstanceId) as HttpAuthHandler?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    assert(
      httpAuthHandlerInstance != null,
      'InstanceManager does not contain a HttpAuthHandler with instanceId: $httpAuthHandlerInstanceId',
    );
    if (instance!.onReceivedHttpAuthRequest != null) {
      return instance.onReceivedHttpAuthRequest!(webViewInstance!, httpAuthHandlerInstance!, host, realm);
    }
  }

  @override
  void onReceivedHttpError(
    int instanceId,
    int webViewInstanceId,
    WebResourceRequestData request,
    WebResourceErrorData error,
  ) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.onReceivedHttpError != null) {
      instance.onReceivedHttpError!(webViewInstance!, _toWebResourceRequest(request), _toWebResourceError(error));
    }
  }

  @override
  void onReceivedSslError(
    int instanceId,
    int webViewInstanceId,
    int sslErrorHandlerInstanceId,
    String url,
    String certificate,
    String description,
  ) {
    final WebViewClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    final SslErrorHandler? sslHandler =
        instanceManager.getInstanceWithWeakReference(sslErrorHandlerInstanceId) as SslErrorHandler?;
    assert(instance != null, 'InstanceManager does not contain a WebViewClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    assert(
      sslHandler != null,
      'InstanceManager does not contain a SslErrorHandler with instanceId: '
      '$sslErrorHandlerInstanceId',
    );
    if (instance!.onReceivedSslError != null) {
      instance.onReceivedSslError!(webViewInstance!, sslHandler!, url, certificate, description);
    } else {
      // ArkTS 与 Android 一样要求显式调用 proceed/cancel，这里默认取消
      unawaited(sslHandler!.cancel());
    }
  }
}

class DownloadListenerHostApiImpl extends DownloadListenerHostApi {
  DownloadListenerHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  Future<void> createFromInstance(DownloadListener instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }
}

class DownloadListenerFlutterApiImpl extends DownloadListenerFlutterApi {
  DownloadListenerFlutterApiImpl({InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  @override
  void onDownloadStart(
    int instanceId,
    String url,
    String userAgent,
    String contentDisposition,
    String mimetype,
    int contentLength,
  ) {
    final DownloadListener? instance = instanceManager.getInstanceWithWeakReference(instanceId) as DownloadListener?;
    assert(instance != null, 'InstanceManager does not contain a DownloadListener with instanceId: $instanceId');
    instance!.onDownloadStart(url, userAgent, contentDisposition, mimetype, contentLength);
  }
}

class WebChromeClientHostApiImpl extends WebChromeClientHostApi {
  WebChromeClientHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  Future<void> createFromInstance(WebChromeClient instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }

  Future<void> setSynchronousReturnValueForOnShowFileChooserFromInstance(WebChromeClient instance, bool value) {
    return setSynchronousReturnValueForOnShowFileChooser(instanceManager.getIdentifier(instance)!, value);
  }

  Future<void> setSynchronousReturnValueForOnConsoleMessageFromInstance(WebChromeClient instance, bool value) {
    return setSynchronousReturnValueForOnConsoleMessage(instanceManager.getIdentifier(instance)!, value);
  }

  Future<void> setSynchronousReturnValueForOnJsAlertFromInstance(WebChromeClient instance, bool value) {
    return setSynchronousReturnValueForOnJsAlert(instanceManager.getIdentifier(instance)!, value);
  }

  Future<void> setSynchronousReturnValueForOnJsConfirmFromInstance(WebChromeClient instance, bool value) {
    return setSynchronousReturnValueForOnJsConfirm(instanceManager.getIdentifier(instance)!, value);
  }

  Future<void> setSynchronousReturnValueForOnJsPromptFromInstance(WebChromeClient instance, bool value) {
    return setSynchronousReturnValueForOnJsPrompt(instanceManager.getIdentifier(instance)!, value);
  }
}

class WebChromeClientFlutterApiImpl extends WebChromeClientFlutterApi {
  WebChromeClientFlutterApiImpl({InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  @override
  void onProgressChanged(int instanceId, int webViewInstanceId, int progress) {
    final WebChromeClient? instance = instanceManager.getInstanceWithWeakReference(instanceId) as WebChromeClient?;
    final WebView? webViewInstance = instanceManager.getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(instance != null, 'InstanceManager does not contain a WebChromeClient with instanceId: $instanceId');
    assert(webViewInstance != null, 'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId');
    if (instance!.onProgressChanged != null) {
      instance.onProgressChanged!(webViewInstance!, progress);
    }
  }

  @override
  Future<List<String?>> onShowFileChooser(int instanceId, int webViewInstanceId, int paramsInstanceId) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;
    if (instance.onShowFileChooser != null) {
      return instance.onShowFileChooser!(
        instanceManager.getInstanceWithWeakReference(webViewInstanceId)! as WebView,
        instanceManager.getInstanceWithWeakReference(paramsInstanceId)! as FileChooserParams,
      );
    }

    return Future<List<String>>.value(const <String>[]);
  }

  @override
  void onGeolocationPermissionsShowPrompt(int instanceId, int paramsInstanceId, String origin) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;
    final GeolocationPermissionsCallback callback =
        instanceManager.getInstanceWithWeakReference(paramsInstanceId)! as GeolocationPermissionsCallback;
    final GeolocationPermissionsShowPrompt? onShowPrompt = instance.onGeolocationPermissionsShowPrompt;
    if (onShowPrompt != null) {
      onShowPrompt(origin, callback);
    }
  }

  @override
  void onGeolocationPermissionsHidePrompt(int identifier) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(identifier)!;
    final GeolocationPermissionsHidePrompt? onHidePrompt = instance.onGeolocationPermissionsHidePrompt;
    if (onHidePrompt != null) {
      return onHidePrompt(instance);
    }
  }

  @override
  void onPermissionRequest(int instanceId, int requestInstanceId) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;
    if (instance.onPermissionRequest != null) {
      instance.onPermissionRequest!(instance, instanceManager.getInstanceWithWeakReference(requestInstanceId)!);
    } else {
      // 覆写 TS 方法后必须调用 grant 或 deny，因此 onPermissionRequest 为空时默认拒绝
      final PermissionRequest request = instanceManager.getInstanceWithWeakReference(requestInstanceId)!;
      request.deny();
    }
  }

  @override
  void onShowCustomView(int instanceId, int viewIdentifier, int callbackIdentifier) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;
    if (instance.onShowCustomView != null) {
      return instance.onShowCustomView!(
        instance,
        instanceManager.getInstanceWithWeakReference(viewIdentifier)!,
        instanceManager.getInstanceWithWeakReference(callbackIdentifier)!,
      );
    }
  }

  @override
  void onHideCustomView(int instanceId) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;
    if (instance.onHideCustomView != null) {
      return instance.onHideCustomView!(instance);
    }
  }

  @override
  void onConsoleMessage(int instanceId, ConsoleMessage message) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;
    instance.onConsoleMessage?.call(instance, message);
  }

  @override
  Future<void> onJsAlert(int instanceId, String url, String message) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;

    return instance.onJsAlert!(url, message);
  }

  @override
  Future<bool> onJsConfirm(int instanceId, String url, String message) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;

    return instance.onJsConfirm!(url, message);
  }

  @override
  Future<String> onJsPrompt(int instanceId, String url, String message, String defaultValue) {
    final WebChromeClient instance = instanceManager.getInstanceWithWeakReference(instanceId)!;

    return instance.onJsPrompt!(url, message, defaultValue);
  }
}

class WebStorageHostApiImpl extends WebStorageHostApi {
  WebStorageHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager instanceManager;

  Future<void> createFromInstance(WebStorage instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }

  Future<void> deleteAllDataFromInstance(WebStorage instance) {
    return deleteAllData(instanceManager.getIdentifier(instance)!);
  }
}

class FileChooserParamsFlutterApiImpl extends FileChooserParamsFlutterApi {
  FileChooserParamsFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(
    int instanceId,
    bool isCaptureEnabled,
    List<String?> acceptTypes,
    FileChooserMode mode,
    String? filenameHint,
  ) {
    instanceManager.addHostCreatedInstance(
      FileChooserParams.detached(
        isCaptureEnabled: isCaptureEnabled,
        acceptTypes: acceptTypes.cast(),
        mode: mode,
        filenameHint: filenameHint,
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      instanceId,
    );
  }
}

class GeolocationPermissionsCallbackHostApiImpl extends GeolocationPermissionsCallbackHostApi {
  GeolocationPermissionsCallbackHostApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager,
      super(binaryMessenger: binaryMessenger);

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  Future<void> invokeFromInstances(GeolocationPermissionsCallback instance, String origin, bool allow, bool retain) {
    return invoke(instanceManager.getIdentifier(instance)!, origin, allow, retain);
  }
}

class GeolocationPermissionsCallbackFlutterApiImpl implements GeolocationPermissionsCallbackFlutterApi {
  GeolocationPermissionsCallbackFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(int instanceId) {
    instanceManager.addHostCreatedInstance(
      GeolocationPermissionsCallback.detached(binaryMessenger: binaryMessenger, instanceManager: instanceManager),
      instanceId,
    );
  }
}

class PermissionRequestHostApiImpl extends PermissionRequestHostApi {
  PermissionRequestHostApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager,
      super(binaryMessenger: binaryMessenger);

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  Future<void> grantFromInstances(PermissionRequest instance, List<String> resources) {
    return grant(instanceManager.getIdentifier(instance)!, resources);
  }

  Future<void> denyFromInstances(PermissionRequest instance) {
    return deny(instanceManager.getIdentifier(instance)!);
  }
}

class PermissionRequestFlutterApiImpl implements PermissionRequestFlutterApi {
  PermissionRequestFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(int identifier, List<String?> resources) {
    instanceManager.addHostCreatedInstance(
      PermissionRequest.detached(
        resources: resources.cast<String>(),
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      identifier,
    );
  }
}

class CustomViewCallbackHostApiImpl extends CustomViewCallbackHostApi {
  CustomViewCallbackHostApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager,
      super(binaryMessenger: binaryMessenger);

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  Future<void> onCustomViewHiddenFromInstances(CustomViewCallback instance) {
    return onCustomViewHidden(instanceManager.getIdentifier(instance)!);
  }
}

class CustomViewCallbackFlutterApiImpl implements CustomViewCallbackFlutterApi {
  CustomViewCallbackFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(int identifier) {
    instanceManager.addHostCreatedInstance(
      CustomViewCallback.detached(binaryMessenger: binaryMessenger, instanceManager: instanceManager),
      identifier,
    );
  }
}

class ViewFlutterApiImpl implements ViewFlutterApi {
  ViewFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(int identifier) {
    instanceManager.addHostCreatedInstance(
      View.detached(binaryMessenger: binaryMessenger, instanceManager: instanceManager),
      identifier,
    );
  }
}

class CookieManagerHostApiImpl extends CookieManagerHostApi {
  CookieManagerHostApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager,
      super(binaryMessenger: binaryMessenger);

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  CookieManager attachInstanceFromInstances(CookieManager instance) {
    attachInstance(instanceManager.addDartCreatedInstance(instance));
    return instance;
  }

  Future<void> setCookieFromInstances(CookieManager instance, String url, String value) {
    return setCookie(instanceManager.getIdentifier(instance)!, url, value);
  }

  Future<String?> getCookiesFromInstances(CookieManager instance, String url) {
    return getCookies(instanceManager.getIdentifier(instance)!, url);
  }

  Future<bool> removeAllCookiesFromInstances(CookieManager instance) {
    return removeAllCookies(instanceManager.getIdentifier(instance)!);
  }

  Future<void> setAcceptThirdPartyCookiesFromInstances(CookieManager instance, WebView webView, bool accept) {
    return setAcceptThirdPartyCookies(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(webView)!,
      accept,
    );
  }
}

class HttpAuthHandlerHostApiImpl extends HttpAuthHandlerHostApi {
  HttpAuthHandlerHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : _instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager _instanceManager;

  Future<void> cancelFromInstance(HttpAuthHandler instance) {
    return cancel(_instanceManager.getIdentifier(instance)!);
  }

  Future<void> proceedFromInstance(HttpAuthHandler instance, String username, String password) {
    return proceed(_instanceManager.getIdentifier(instance)!, username, password);
  }

  Future<bool> useHttpAuthUsernamePasswordFromInstance(HttpAuthHandler instance) {
    return useHttpAuthUsernamePassword(_instanceManager.getIdentifier(instance)!);
  }
}

class HttpAuthHandlerFlutterApiImpl extends HttpAuthHandlerFlutterApi {
  HttpAuthHandlerFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(int instanceId) {
    instanceManager.addHostCreatedInstance(HttpAuthHandler(), instanceId);
  }
}

class SslErrorHandlerHostApiImpl extends SslErrorHandlerHostApi {
  SslErrorHandlerHostApiImpl({super.binaryMessenger, InstanceManager? instanceManager})
    : _instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final InstanceManager _instanceManager;

  Future<void> cancelFromInstance(SslErrorHandler instance) {
    return cancel(_instanceManager.getIdentifier(instance)!);
  }

  Future<void> proceedFromInstance(SslErrorHandler instance) {
    return proceed(_instanceManager.getIdentifier(instance)!);
  }
}

class SslErrorHandlerFlutterApiImpl extends SslErrorHandlerFlutterApi {
  SslErrorHandlerFlutterApiImpl({this.binaryMessenger, InstanceManager? instanceManager})
    : instanceManager = instanceManager ?? OhosObject.globalInstanceManager;

  final BinaryMessenger? binaryMessenger;

  final InstanceManager instanceManager;

  @override
  void create(int instanceId) {
    instanceManager.addHostCreatedInstance(SslErrorHandler(), instanceId);
  }
}
