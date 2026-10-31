// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show BinaryMessenger;

import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;

import 'package:webview_flutter_harmonyos/src/ohos_webview.g.dart';
import 'package:webview_flutter_harmonyos/src/ohos_webview_api_impls.dart';
import 'package:webview_flutter_harmonyos/src/instance_manager.dart';

export 'ohos_webview_api_impls.dart' show ConsoleMessage, ConsoleMessageLevel, FileChooserMode;

class OhosObject with Copyable {
  @protected
  OhosObject.detached({BinaryMessenger? binaryMessenger, InstanceManager? instanceManager})
    : _api = OhosObjectHostApiImpl(binaryMessenger: binaryMessenger, instanceManager: instanceManager);

  static final InstanceManager globalInstanceManager = _initInstanceManager();

  static InstanceManager _initInstanceManager() {
    WidgetsFlutterBinding.ensureInitialized();
    // 首次使用 Dart 侧 InstanceManager 时清除原生侧实例
    InstanceManagerHostApi().clear();
    return InstanceManager(
      onWeakReferenceRemoved: (int identifier) {
        OhosObjectHostApiImpl().dispose(identifier);
      },
    );
  }

  final OhosObjectHostApiImpl _api;

  static void dispose(OhosObject instance) {
    instance._api.instanceManager.removeWeakReference(instance);
  }

  @override
  OhosObject copy() {
    return OhosObject.detached();
  }
}

@immutable
class GeolocationPermissionsCallback extends OhosObject {
  @protected
  GeolocationPermissionsCallback.detached({super.binaryMessenger, super.instanceManager})
    : _geolocationPermissionsCallbackApi = GeolocationPermissionsCallbackHostApiImpl(
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      super.detached();

  final GeolocationPermissionsCallbackHostApiImpl _geolocationPermissionsCallbackApi;

  Future<void> invoke(String origin, bool allow, bool retain) {
    return _geolocationPermissionsCallbackApi.invokeFromInstances(this, origin, allow, retain);
  }

  @override
  GeolocationPermissionsCallback copy() {
    return GeolocationPermissionsCallback.detached(
      binaryMessenger: _geolocationPermissionsCallbackApi.binaryMessenger,
      instanceManager: _geolocationPermissionsCallbackApi.instanceManager,
    );
  }
}

class WebView extends OhosObject {
  WebView({this.onScrollChanged, @visibleForTesting super.binaryMessenger, @visibleForTesting super.instanceManager})
    : super.detached() {
    api.createFromInstance(this);
  }

  @protected
  WebView.detached({this.onScrollChanged, super.binaryMessenger, super.instanceManager}) : super.detached();

  @visibleForTesting
  static WebViewHostApiImpl api = WebViewHostApiImpl();

  late final WebSettings settings = WebSettings(this);

  final void Function(int left, int top, int oldLeft, int oldTop)? onScrollChanged;

  static Future<void> setWebContentsDebuggingEnabled(bool enabled) {
    return api.setWebContentsDebuggingEnabled(enabled);
  }

  Future<void> loadData({required String data, String? mimeType, String? encoding}) {
    return api.loadDataFromInstance(this, data, mimeType, encoding);
  }

  Future<void> loadDataWithBaseUrl({
    String? baseUrl,
    required String data,
    String? mimeType,
    String? encoding,
    String? historyUrl,
  }) {
    return api.loadDataWithBaseUrlFromInstance(this, baseUrl, data, mimeType, encoding, historyUrl);
  }

  Future<void> loadUrl(String url, Map<String, String> headers) {
    return api.loadUrlFromInstance(this, url, headers);
  }

  Future<void> postUrl(String url, Uint8List data) {
    return api.postUrlFromInstance(this, url, data);
  }

  Future<String?> getUrl() {
    return api.getUrlFromInstance(this);
  }

  Future<bool> canGoBack() {
    return api.canGoBackFromInstance(this);
  }

  Future<bool> canGoForward() {
    return api.canGoForwardFromInstance(this);
  }

  Future<void> goBack() {
    return api.goBackFromInstance(this);
  }

  Future<void> goForward() {
    return api.goForwardFromInstance(this);
  }

  Future<void> reload() {
    return api.reloadFromInstance(this);
  }

  Future<void> clearCache(bool includeDiskFiles) {
    return api.clearCacheFromInstance(this, includeDiskFiles);
  }

  Future<String?> evaluateJavascript(String javascriptString) {
    return api.evaluateJavascriptFromInstance(this, javascriptString);
  }

  Future<String?> getTitle() {
    return api.getTitleFromInstance(this);
  }

  Future<void> scrollTo(int x, int y) {
    return api.scrollToFromInstance(this, x, y);
  }

  Future<void> scrollBy(int x, int y) {
    return api.scrollByFromInstance(this, x, y);
  }

  Future<int> getScrollX() {
    return api.getScrollXFromInstance(this);
  }

  Future<int> getScrollY() {
    return api.getScrollYFromInstance(this);
  }

  Future<Offset> getScrollPosition() {
    return api.getScrollPositionFromInstance(this);
  }

  Future<void> setWebViewClient(WebViewClient webViewClient) {
    return api.setWebViewClientFromInstance(this, webViewClient);
  }

  Future<void> addJavaScriptChannel(JavaScriptChannel javaScriptChannel) {
    JavaScriptChannel.api.createFromInstance(javaScriptChannel);
    return api.addJavaScriptChannelFromInstance(this, javaScriptChannel);
  }

  Future<void> removeJavaScriptChannel(JavaScriptChannel javaScriptChannel) {
    JavaScriptChannel.api.createFromInstance(javaScriptChannel);
    return api.removeJavaScriptChannelFromInstance(this, javaScriptChannel);
  }

  Future<void> setDownloadListener(DownloadListener? listener) {
    return api.setDownloadListenerFromInstance(this, listener);
  }

  Future<void> setWebChromeClient(WebChromeClient? client) {
    return api.setWebChromeClientFromInstance(this, client);
  }

  @override
  WebView copy() {
    return WebView.detached(
      onScrollChanged: onScrollChanged,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

class CookieManager extends OhosObject {
  @protected
  CookieManager.detached({super.binaryMessenger, super.instanceManager})
    : _cookieManagerApi = CookieManagerHostApiImpl(binaryMessenger: binaryMessenger, instanceManager: instanceManager),
      super.detached();

  static final CookieManager _instance = CookieManagerHostApiImpl().attachInstanceFromInstances(
    CookieManager.detached(),
  );

  final CookieManagerHostApiImpl _cookieManagerApi;

  static CookieManager get instance {
    OhosWebViewFlutterApis.instance.ensureSetUp();
    return _instance;
  }

  Future<void> setCookie(String url, String value) {
    return _cookieManagerApi.setCookieFromInstances(this, url, value);
  }

  Future<String?> getCookies(String url) {
    return _cookieManagerApi.getCookiesFromInstances(this, url);
  }

  Future<bool> removeAllCookies() {
    return _cookieManagerApi.removeAllCookiesFromInstances(this);
  }

  Future<void> setAcceptThirdPartyCookies(WebView webView, bool accept) {
    return _cookieManagerApi.setAcceptThirdPartyCookiesFromInstances(this, webView, accept);
  }

  @override
  CookieManager copy() {
    return CookieManager.detached(
      binaryMessenger: _cookieManagerApi.binaryMessenger,
      instanceManager: _cookieManagerApi.instanceManager,
    );
  }
}

class WebSettings extends OhosObject {
  @visibleForTesting
  WebSettings(WebView webView, {@visibleForTesting super.binaryMessenger, @visibleForTesting super.instanceManager})
    : super.detached() {
    api.createFromInstance(this, webView);
  }

  @protected
  WebSettings.detached({super.binaryMessenger, super.instanceManager}) : super.detached();

  @visibleForTesting
  static WebSettingsHostApiImpl api = WebSettingsHostApiImpl();

  Future<void> setDomStorageEnabled(bool flag) {
    return api.setDomStorageEnabledFromInstance(this, flag);
  }

  Future<void> setJavaScriptCanOpenWindowsAutomatically(bool flag) {
    return api.setJavaScriptCanOpenWindowsAutomaticallyFromInstance(this, flag);
  }

  Future<void> setSupportMultipleWindows(bool support) {
    return api.setSupportMultipleWindowsFromInstance(this, support);
  }

  Future<void> setBackgroundColor(Color color) {
    return api.setBackgroundColorFromInstance(this, color.toARGB32());
  }

  Future<void> setJavaScriptEnabled(bool flag) {
    return api.setJavaScriptEnabledFromInstance(this, flag);
  }

  Future<void> setUserAgentString(String? userAgentString) {
    return api.setUserAgentStringFromInstance(this, userAgentString);
  }

  Future<void> setMediaPlaybackRequiresUserGesture(bool require) {
    return api.setMediaPlaybackRequiresUserGestureFromInstance(this, require);
  }

  Future<void> setSupportZoom(bool support) {
    return api.setSupportZoomFromInstance(this, support);
  }

  Future<void> setLoadWithOverviewMode(bool overview) {
    return api.setLoadWithOverviewModeFromInstance(this, overview);
  }

  Future<void> setUseWideViewPort(bool use) {
    return api.setUseWideViewPortFromInstance(this, use);
  }

  Future<void> setDisplayZoomControls(bool enabled) {
    return api.setDisplayZoomControlsFromInstance(this, enabled);
  }

  Future<void> setBuiltInZoomControls(bool enabled) {
    return api.setBuiltInZoomControlsFromInstance(this, enabled);
  }

  Future<void> setAllowFileAccess(bool enabled) {
    return api.setAllowFileAccessFromInstance(this, enabled);
  }

  Future<void> setTextZoom(int textZoom) {
    return api.setSetTextZoomFromInstance(this, textZoom);
  }

  Future<String> getUserAgentString() {
    return api.getUserAgentStringFromInstance(this);
  }

  Future<void> setAllowFullScreenRotate(bool enabled) {
    return api.setAllowFullScreenRotateInstance(this, enabled);
  }

  Future<void> setMixedContentMode(MixedContentMode mode) {
    return api.setMixedContentModeFromInstance(this, mode);
  }

  Future<void> setOverScrollMode(OverScrollMode mode) {
    return api.setOverScrollModeFromInstance(this, mode);
  }

  Future<void> setVerticalScrollBarAccessEnabled(bool enabled) {
    return api.setVerticalScrollBarAccessEnabledFromInstance(this, enabled);
  }

  Future<void> setHorizontalScrollBarAccessEnabled(bool enabled) {
    return api.setHorizontalScrollBarAccessEnabledFromInstance(this, enabled);
  }

  @override
  WebSettings copy() {
    return WebSettings.detached(binaryMessenger: _api.binaryMessenger, instanceManager: _api.instanceManager);
  }
}

enum MixedContentMode { alwaysAllow, compatibilityMode, neverAllow }

enum OverScrollMode { never, always }

class WebSettingsCompat {
  static Future<void> setPaymentRequestEnabled(WebSettings webSettings, bool enabled) {
    return WebSettings.api.setPaymentRequestEnabledFromInstance(webSettings, enabled);
  }
}

class WebViewFeature {
  @visibleForTesting
  static WebViewFeatureHostApi api = WebViewFeatureHostApi();

  static Future<bool> isFeatureSupported(String feature) {
    return api.isFeatureSupported(feature);
  }
}

class JavaScriptChannel extends OhosObject {
  JavaScriptChannel(
    this.channelName, {
    required this.postMessage,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    OhosWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  @protected
  JavaScriptChannel.detached(
    this.channelName, {
    required this.postMessage,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  @visibleForTesting
  static JavaScriptChannelHostApiImpl api = JavaScriptChannelHostApiImpl();

  final String channelName;

  final void Function(String message) postMessage;

  @override
  JavaScriptChannel copy() {
    return JavaScriptChannel.detached(
      channelName,
      postMessage: postMessage,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

class WebViewClient extends OhosObject {
  WebViewClient({
    this.onPageStarted,
    this.onPageFinished,
    this.onReceivedRequestError,
    @Deprecated('Only called on Ohos version < 23.') this.onReceivedError,
    this.requestLoading,
    this.urlLoading,
    this.doUpdateVisitedHistory,
    this.onReceivedHttpAuthRequest,
    this.onReceivedHttpError,
    this.onReceivedSslError,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    OhosWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  @protected
  WebViewClient.detached({
    this.onPageStarted,
    this.onPageFinished,
    this.onReceivedRequestError,
    @Deprecated('Only called on Ohos version < 23.') this.onReceivedError,
    this.requestLoading,
    this.urlLoading,
    this.doUpdateVisitedHistory,
    this.onReceivedHttpAuthRequest,
    this.onReceivedHttpError,
    this.onReceivedSslError,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  // ArkWeb 网络协议栈错误列表，参考 @ohos.web.netErrorList
  static const int errorAuthentication = -100;

  static const int errorBadUrl = -300;

  static const int errorConnect = -106;

  static const int errorFailedSslHandshake = -148;

  static const int errorFile = -16;

  static const int errorFileNotFound = -808;

  static const int errorHostLookup = -121;

  static const int errorIO = -1;

  static const int errorProxyAuthentication = -115;

  static const int errorRedirectLoop = -303;

  static const int errorTimeout = -409;

  static const int errorTooManyRequests = -114;

  static const int errorUnknown = -9;

  static const int errorUnsafeResource = -311;

  static const int errorUnsupportedAuthScheme = -339;

  static const int errorUnsupportedScheme = -301;

  @visibleForTesting
  static WebViewClientHostApiImpl api = WebViewClientHostApiImpl();

  final void Function(WebView webView, String url)? onPageStarted;

  final void Function(WebView webView, String url)? onPageFinished;

  final void Function(WebView webView, WebResourceRequest request, WebResourceError error)? onReceivedRequestError;

  @Deprecated('Only called on Ohos version < 23.')
  final void Function(WebView webView, int errorCode, String description, String failingUrl)? onReceivedError;

  final void Function(WebView webView, WebResourceRequest request)? requestLoading;

  final void Function(WebView webView, String url)? urlLoading;

  final void Function(WebView webView, String url, bool isReload)? doUpdateVisitedHistory;

  final void Function(WebView webView, HttpAuthHandler handler, String host, String realm)? onReceivedHttpAuthRequest;

  final void Function(WebView webView, WebResourceRequest request, WebResourceError error)? onReceivedHttpError;

  final void Function(WebView webView, SslErrorHandler handler, String url, String certificate, String description)?
  onReceivedSslError;

  Future<void> setSynchronousReturnValueForShouldOverrideUrlLoading(bool value) {
    return api.setShouldOverrideUrlLoadingReturnValueFromInstance(this, value);
  }

  @override
  WebViewClient copy() {
    return WebViewClient.detached(
      onPageStarted: onPageStarted,
      onPageFinished: onPageFinished,
      onReceivedRequestError: onReceivedRequestError,
      onReceivedError: onReceivedError,
      requestLoading: requestLoading,
      urlLoading: urlLoading,
      doUpdateVisitedHistory: doUpdateVisitedHistory,
      onReceivedHttpAuthRequest: onReceivedHttpAuthRequest,
      onReceivedHttpError: onReceivedHttpError,
      onReceivedSslError: onReceivedSslError,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

class DownloadListener extends OhosObject {
  DownloadListener({
    required this.onDownloadStart,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    OhosWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  @protected
  DownloadListener.detached({required this.onDownloadStart, super.binaryMessenger, super.instanceManager})
    : super.detached();

  @visibleForTesting
  static DownloadListenerHostApiImpl api = DownloadListenerHostApiImpl();

  final void Function(String url, String userAgent, String contentDisposition, String mimetype, int contentLength)
  onDownloadStart;

  @override
  DownloadListener copy() {
    return DownloadListener.detached(
      onDownloadStart: onDownloadStart,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

typedef GeolocationPermissionsShowPrompt =
    Future<void> Function(String origin, GeolocationPermissionsCallback callback);

typedef GeolocationPermissionsHidePrompt = void Function(WebChromeClient instance);

typedef ShowCustomViewCallback = void Function(WebChromeClient instance, View view, CustomViewCallback callback);

typedef HideCustomViewCallback = void Function(WebChromeClient instance);

class WebChromeClient extends OhosObject {
  WebChromeClient({
    this.onProgressChanged,
    this.onShowFileChooser,
    this.onPermissionRequest,
    this.onGeolocationPermissionsShowPrompt,
    this.onGeolocationPermissionsHidePrompt,
    this.onShowCustomView,
    this.onHideCustomView,
    this.onConsoleMessage,
    this.onJsAlert,
    this.onJsConfirm,
    this.onJsPrompt,
    @visibleForTesting super.binaryMessenger,
    @visibleForTesting super.instanceManager,
  }) : super.detached() {
    OhosWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  @protected
  WebChromeClient.detached({
    this.onProgressChanged,
    this.onShowFileChooser,
    this.onPermissionRequest,
    this.onGeolocationPermissionsShowPrompt,
    this.onGeolocationPermissionsHidePrompt,
    this.onShowCustomView,
    this.onHideCustomView,
    this.onConsoleMessage,
    this.onJsAlert,
    this.onJsConfirm,
    this.onJsPrompt,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  @visibleForTesting
  static WebChromeClientHostApiImpl api = WebChromeClientHostApiImpl();

  final void Function(WebView webView, int progress)? onProgressChanged;

  final Future<List<String>> Function(WebView webView, FileChooserParams params)? onShowFileChooser;

  final void Function(WebChromeClient instance, PermissionRequest request)? onPermissionRequest;

  final GeolocationPermissionsShowPrompt? onGeolocationPermissionsShowPrompt;

  final GeolocationPermissionsHidePrompt? onGeolocationPermissionsHidePrompt;

  final ShowCustomViewCallback? onShowCustomView;

  final HideCustomViewCallback? onHideCustomView;

  final void Function(WebChromeClient instance, ConsoleMessage message)? onConsoleMessage;

  final Future<void> Function(String url, String message)? onJsAlert;

  final Future<bool> Function(String url, String message)? onJsConfirm;

  final Future<String> Function(String url, String message, String defaultValue)? onJsPrompt;

  Future<void> setSynchronousReturnValueForOnShowFileChooser(bool value) {
    if (value && onShowFileChooser == null) {
      throw StateError('Setting this to true requires `onShowFileChooser` to be nonnull.');
    }
    return api.setSynchronousReturnValueForOnShowFileChooserFromInstance(this, value);
  }

  Future<void> setSynchronousReturnValueForOnConsoleMessage(bool value) {
    if (value && onConsoleMessage == null) {
      throw StateError('Setting this to true requires `onConsoleMessage` to be nonnull.');
    }
    return api.setSynchronousReturnValueForOnConsoleMessageFromInstance(this, value);
  }

  Future<void> setSynchronousReturnValueForOnJsAlert(bool value) {
    if (value && onJsAlert == null) {
      throw StateError('Setting this to true requires `onJsAlert` to be nonnull.');
    }
    return api.setSynchronousReturnValueForOnJsAlertFromInstance(this, value);
  }

  Future<void> setSynchronousReturnValueForOnJsConfirm(bool value) {
    if (value && onJsConfirm == null) {
      throw StateError('Setting this to true requires `onJsConfirm` to be nonnull.');
    }
    return api.setSynchronousReturnValueForOnJsConfirmFromInstance(this, value);
  }

  Future<void> setSynchronousReturnValueForOnJsPrompt(bool value) {
    if (value && onJsPrompt == null) {
      throw StateError('Setting this to true requires `onJsPrompt` to be nonnull.');
    }
    return api.setSynchronousReturnValueForOnJsPromptFromInstance(this, value);
  }

  @override
  WebChromeClient copy() {
    return WebChromeClient.detached(
      onProgressChanged: onProgressChanged,
      onShowFileChooser: onShowFileChooser,
      onPermissionRequest: onPermissionRequest,
      onGeolocationPermissionsShowPrompt: onGeolocationPermissionsShowPrompt,
      onGeolocationPermissionsHidePrompt: onGeolocationPermissionsHidePrompt,
      onShowCustomView: onShowCustomView,
      onHideCustomView: onHideCustomView,
      onConsoleMessage: onConsoleMessage,
      onJsAlert: onJsAlert,
      onJsConfirm: onJsConfirm,
      onJsPrompt: onJsPrompt,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

class PermissionRequest extends OhosObject {
  @protected
  PermissionRequest.detached({required this.resources, required super.binaryMessenger, required super.instanceManager})
    : _permissionRequestApi = PermissionRequestHostApiImpl(
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      super.detached();

  static const String audioCapture = 'TYPE_AUDIO_CAPTURE';

  static const String midiSysex = 'TYPE_MIDI_SYSEX';

  static const String videoCapture = 'TYPE_VIDEO_CAPTURE';

  static const String protectedMediaId = 'ohos.webkit.resource.PROTECTED_MEDIA_ID';

  final PermissionRequestHostApiImpl _permissionRequestApi;

  final List<String> resources;

  Future<void> grant(List<String> resources) {
    return _permissionRequestApi.grantFromInstances(this, resources);
  }

  Future<void> deny() {
    return _permissionRequestApi.denyFromInstances(this);
  }

  @override
  PermissionRequest copy() {
    return PermissionRequest.detached(
      resources: resources,
      binaryMessenger: _permissionRequestApi.binaryMessenger,
      instanceManager: _permissionRequestApi.instanceManager,
    );
  }
}

class FileChooserParams extends OhosObject {
  @protected
  FileChooserParams.detached({
    required this.isCaptureEnabled,
    required this.acceptTypes,
    required this.filenameHint,
    required this.mode,
    super.binaryMessenger,
    super.instanceManager,
  }) : super.detached();

  final bool isCaptureEnabled;

  final List<String> acceptTypes;

  final String? filenameHint;

  final FileChooserMode mode;

  @override
  FileChooserParams copy() {
    return FileChooserParams.detached(
      isCaptureEnabled: isCaptureEnabled,
      acceptTypes: acceptTypes,
      filenameHint: filenameHint,
      mode: mode,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

class WebResourceRequest {
  WebResourceRequest({
    required this.url,
    required this.isForMainFrame,
    required this.isRedirect,
    required this.hasGesture,
    required this.method,
    required this.requestHeaders,
  });

  final String url;

  final bool isForMainFrame;

  final bool? isRedirect;

  final bool hasGesture;

  final String method;

  final Map<String, String> requestHeaders;
}

class WebResourceError {
  WebResourceError({required this.errorCode, required this.description});

  final int errorCode;

  final String description;
}

class FlutterAssetManager {
  const FlutterAssetManager();

  static const FlutterAssetManager instance = FlutterAssetManager();

  @visibleForTesting
  static FlutterAssetManagerHostApi api = FlutterAssetManagerHostApi();

  Future<List<String?>> list(String path) => api.list(path);

  Future<String> getAssetFilePathByName(String name) => api.getAssetFilePathByName(name);
}

class WebStorage extends OhosObject {
  @visibleForTesting
  WebStorage({@visibleForTesting super.binaryMessenger, @visibleForTesting super.instanceManager}) : super.detached() {
    OhosWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  @protected
  WebStorage.detached({super.binaryMessenger, super.instanceManager}) : super.detached();

  @visibleForTesting
  static WebStorageHostApiImpl api = WebStorageHostApiImpl();

  static WebStorage instance = WebStorage();

  Future<void> deleteAllData() {
    return api.deleteAllDataFromInstance(this);
  }

  @override
  WebStorage copy() {
    return WebStorage.detached(binaryMessenger: _api.binaryMessenger, instanceManager: _api.instanceManager);
  }
}

class View extends OhosObject {
  @protected
  View.detached({super.binaryMessenger, super.instanceManager}) : super.detached();

  @override
  View copy() {
    return View.detached(binaryMessenger: _api.binaryMessenger, instanceManager: _api.instanceManager);
  }
}

class CustomViewCallback extends OhosObject {
  @protected
  CustomViewCallback.detached({super.binaryMessenger, super.instanceManager})
    : _customViewCallbackApi = CustomViewCallbackHostApiImpl(
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      super.detached();

  final CustomViewCallbackHostApiImpl _customViewCallbackApi;

  Future<void> onCustomViewHidden() {
    return _customViewCallbackApi.onCustomViewHiddenFromInstances(this);
  }

  @override
  CustomViewCallback copy() {
    return CustomViewCallback.detached(
      binaryMessenger: _customViewCallbackApi.binaryMessenger,
      instanceManager: _customViewCallbackApi.instanceManager,
    );
  }
}

class HttpAuthHandler extends OhosObject {
  HttpAuthHandler({super.binaryMessenger, super.instanceManager}) : super.detached();

  @visibleForTesting
  static HttpAuthHandlerHostApiImpl api = HttpAuthHandlerHostApiImpl();

  Future<void> cancel() {
    return api.cancelFromInstance(this);
  }

  Future<void> proceed(String username, String password) {
    return api.proceedFromInstance(this, username, password);
  }

  Future<bool> useHttpAuthUsernamePassword() {
    return api.useHttpAuthUsernamePasswordFromInstance(this);
  }
}

class SslErrorHandler extends OhosObject {
  SslErrorHandler({super.binaryMessenger, super.instanceManager}) : super.detached();

  @visibleForTesting
  static SslErrorHandlerHostApiImpl api = SslErrorHandlerHostApiImpl();

  Future<void> cancel() {
    return api.cancelFromInstance(this);
  }

  Future<void> proceed() {
    return api.proceedFromInstance(this);
  }
}
