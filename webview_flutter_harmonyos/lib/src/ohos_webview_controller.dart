// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:webview_flutter_harmonyos/src/ohos_webview.dart' as ohos_webview;
import 'package:webview_flutter_harmonyos/src/webview_feature_constants.dart';
import 'package:webview_flutter_harmonyos/src/ohos_webview_api_impls.dart';
import 'package:webview_flutter_harmonyos/src/ohos_ssl_auth_error.dart';
import 'package:webview_flutter_harmonyos/src/platform_views_service_proxy.dart';
import 'package:webview_flutter_harmonyos/src/weak_reference_utils.dart';

@immutable
base class OhosLoadFileParams extends LoadFileParams {
  OhosLoadFileParams({required String absoluteFilePath, this.headers = const <String, String>{}})
    : super(
        absoluteFilePath: absoluteFilePath.startsWith('file://')
            ? absoluteFilePath
            : Uri.file(absoluteFilePath).toString(),
      );

  factory OhosLoadFileParams.fromLoadFileParams(
    LoadFileParams params, {
    Map<String, String> headers = const <String, String>{},
  }) {
    return OhosLoadFileParams(absoluteFilePath: params.absoluteFilePath, headers: headers);
  }

  final Map<String, String> headers;
}

@immutable
class OhosWebViewControllerCreationParams extends PlatformWebViewControllerCreationParams {
  OhosWebViewControllerCreationParams({
    this.isAllowFullScreenRotate = false,
    @visibleForTesting ohos_webview.WebStorage? ohosWebStorage,
  }) : ohosWebStorage = ohosWebStorage ?? ohos_webview.WebStorage.instance,
       super();

  factory OhosWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
    // 保留占位参数，避免平台接口变更时签名不兼容
    // ignore: avoid_unused_constructor_parameters
    PlatformWebViewControllerCreationParams params, {
    bool? isAllowFullScreenRotate = false,
    @visibleForTesting ohos_webview.WebStorage? ohosWebStorage,
  }) {
    return OhosWebViewControllerCreationParams(
      isAllowFullScreenRotate: isAllowFullScreenRotate,
      ohosWebStorage: ohosWebStorage ?? ohos_webview.WebStorage.instance,
    );
  }

  final bool? isAllowFullScreenRotate;

  @visibleForTesting
  final ohos_webview.WebStorage ohosWebStorage;
}

class OhosWebViewPermissionResourceType extends WebViewPermissionResourceType {
  const OhosWebViewPermissionResourceType._(super.name);

  static const OhosWebViewPermissionResourceType midiSysex = OhosWebViewPermissionResourceType._('midiSysex');

  static const OhosWebViewPermissionResourceType protectedMediaId = OhosWebViewPermissionResourceType._(
    'protectedMediaId',
  );
}

class OhosWebViewController extends PlatformWebViewController {
  OhosWebViewController(PlatformWebViewControllerCreationParams params)
    : super.implementation(
        params is OhosWebViewControllerCreationParams
            ? params
            : OhosWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(params),
      ) {
    _webView.settings.setAllowFullScreenRotate(
      params is OhosWebViewControllerCreationParams ? params.isAllowFullScreenRotate ?? false : false,
    );
    _webView.settings.setDomStorageEnabled(true);
    _webView.settings.setJavaScriptCanOpenWindowsAutomatically(true);
    _webView.settings.setSupportMultipleWindows(true);
    _webView.settings.setLoadWithOverviewMode(true);
    _webView.settings.setUseWideViewPort(true);
    _webView.settings.setDisplayZoomControls(false);
    _webView.settings.setBuiltInZoomControls(true);

    _webView.setWebChromeClient(_webChromeClient);
  }

  OhosWebViewControllerCreationParams get _ohosWebViewParams => params as OhosWebViewControllerCreationParams;

  late final ohos_webview.WebView _webView = ohos_webview.WebView(
    onScrollChanged: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (int left, int top, int oldLeft, int oldTop) async {
        final void Function(ScrollPositionChange)? callback = weakReference.target?._onScrollPositionChangedCallback;
        callback?.call(ScrollPositionChange(left.toDouble(), top.toDouble()));
      };
    }),
  );

  late final ohos_webview.WebChromeClient _webChromeClient = ohos_webview.WebChromeClient(
    onProgressChanged: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (ohos_webview.WebView webView, int progress) {
        if (weakReference.target?._currentNavigationDelegate?._onProgress != null) {
          weakReference.target!._currentNavigationDelegate!._onProgress!(progress);
        }
      };
    }),
    onGeolocationPermissionsShowPrompt: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (String origin, ohos_webview.GeolocationPermissionsCallback callback) async {
        final OnGeolocationPermissionsShowPrompt? onShowPrompt =
            weakReference.target?._onGeolocationPermissionsShowPrompt;
        if (onShowPrompt != null) {
          final GeolocationPermissionsResponse response = await onShowPrompt(
            GeolocationPermissionsRequestParams(origin: origin),
          );
          return callback.invoke(origin, response.allow, response.retain);
        } else {
          return callback.invoke(origin, false, false);
        }
      };
    }),
    onGeolocationPermissionsHidePrompt: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (ohos_webview.WebChromeClient instance) {
        final OnGeolocationPermissionsHidePrompt? onHidePrompt =
            weakReference.target?._onGeolocationPermissionsHidePrompt;
        if (onHidePrompt != null) {
          onHidePrompt();
        }
      };
    }),
    onShowCustomView: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (_, ohos_webview.View view, ohos_webview.CustomViewCallback callback) {
        final OhosWebViewController? webViewController = weakReference.target;
        if (webViewController == null) {
          callback.onCustomViewHidden();
          return;
        }
        final OnShowCustomWidgetCallback? onShowCallback = webViewController._onShowCustomWidgetCallback;
        if (onShowCallback == null) {
          callback.onCustomViewHidden();
          return;
        }
        onShowCallback(
          OhosCustomViewWidget.private(controller: webViewController, customView: view),
          () => callback.onCustomViewHidden(),
        );
      };
    }),
    onHideCustomView: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (ohos_webview.WebChromeClient instance) {
        final OnHideCustomWidgetCallback? onHideCustomViewCallback = weakReference.target?._onHideCustomWidgetCallback;
        if (onHideCustomViewCallback != null) {
          onHideCustomViewCallback();
        }
      };
    }),
    onShowFileChooser: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (ohos_webview.WebView webView, ohos_webview.FileChooserParams params) async {
        if (weakReference.target?._onShowFileSelectorCallback != null) {
          return weakReference.target!._onShowFileSelectorCallback!(FileSelectorParams._fromFileChooserParams(params));
        }
        return <String>[];
      };
    }),
    onConsoleMessage: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (ohos_webview.WebChromeClient webChromeClient, ohos_webview.ConsoleMessage consoleMessage) async {
        final void Function(JavaScriptConsoleMessage)? callback = weakReference.target?._onConsoleLogCallback;
        if (callback != null) {
          JavaScriptLogLevel logLevel;
          switch (consoleMessage.level) {
            // Android 将 console.debug 映射为 MessageLevel.TIP，这里同样把两者都视为 debug
            case ConsoleMessageLevel.debug:
            case ConsoleMessageLevel.tip:
              logLevel = JavaScriptLogLevel.debug;
              break;
            case ConsoleMessageLevel.error:
              logLevel = JavaScriptLogLevel.error;
              break;
            case ConsoleMessageLevel.warning:
              logLevel = JavaScriptLogLevel.warning;
              break;
            case ConsoleMessageLevel.unknown:
            case ConsoleMessageLevel.log:
              logLevel = JavaScriptLogLevel.log;
              break;
          }

          callback(JavaScriptConsoleMessage(level: logLevel, message: consoleMessage.message));
        }
      };
    }),
    onPermissionRequest: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (_, ohos_webview.PermissionRequest request) async {
        final void Function(PlatformWebViewPermissionRequest)? callback =
            weakReference.target?._onPermissionRequestCallback;
        if (callback == null) {
          return request.deny();
        } else {
          final Set<WebViewPermissionResourceType> types = request.resources
              .map<WebViewPermissionResourceType?>((String type) {
                switch (type) {
                  case ohos_webview.PermissionRequest.videoCapture:
                    return WebViewPermissionResourceType.camera;
                  case ohos_webview.PermissionRequest.audioCapture:
                    return WebViewPermissionResourceType.microphone;
                  case ohos_webview.PermissionRequest.midiSysex:
                    return OhosWebViewPermissionResourceType.midiSysex;
                  case ohos_webview.PermissionRequest.protectedMediaId:
                    return OhosWebViewPermissionResourceType.protectedMediaId;
                }

                return null;
              })
              .whereType<WebViewPermissionResourceType>()
              .toSet();

          // 请求中没有可识别的权限时默认拒绝
          if (types.isEmpty) {
            return request.deny();
          }

          callback(OhosWebViewPermissionRequest._(types: types, request: request));
        }
      };
    }),
    onJsAlert: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (String url, String message) async {
        final Future<void> Function(JavaScriptAlertDialogRequest)? callback = weakReference.target?._onJavaScriptAlert;
        if (callback != null) {
          final request = JavaScriptAlertDialogRequest(message: message, url: url);

          await callback.call(request);
        }
        return;
      };
    }),
    onJsConfirm: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (String url, String message) async {
        final Future<bool> Function(JavaScriptConfirmDialogRequest)? callback =
            weakReference.target?._onJavaScriptConfirm;
        if (callback != null) {
          final request = JavaScriptConfirmDialogRequest(message: message, url: url);
          final bool result = await callback.call(request);
          return result;
        }
        return false;
      };
    }),
    onJsPrompt: withWeakReferenceTo(this, (WeakReference<OhosWebViewController> weakReference) {
      return (String url, String message, String defaultValue) async {
        final Future<String> Function(JavaScriptTextInputDialogRequest)? callback =
            weakReference.target?._onJavaScriptPrompt;
        if (callback != null) {
          final request = JavaScriptTextInputDialogRequest(message: message, url: url, defaultText: defaultValue);
          final String result = await callback.call(request);
          return result;
        }
        return '';
      };
    }),
  );

  late final ohos_webview.FlutterAssetManager _flutterAssetManager = ohos_webview.FlutterAssetManager.instance;

  final Map<String, OhosJavaScriptChannelParams> _javaScriptChannelParams = <String, OhosJavaScriptChannelParams>{};

  OhosNavigationDelegate? _currentNavigationDelegate;

  Future<List<String>> Function(FileSelectorParams)? _onShowFileSelectorCallback;

  OnGeolocationPermissionsShowPrompt? _onGeolocationPermissionsShowPrompt;

  OnGeolocationPermissionsHidePrompt? _onGeolocationPermissionsHidePrompt;

  OnShowCustomWidgetCallback? _onShowCustomWidgetCallback;

  OnHideCustomWidgetCallback? _onHideCustomWidgetCallback;

  void Function(PlatformWebViewPermissionRequest)? _onPermissionRequestCallback;

  void Function(JavaScriptConsoleMessage consoleMessage)? _onConsoleLogCallback;

  Future<void> Function(JavaScriptAlertDialogRequest request)? _onJavaScriptAlert;
  Future<bool> Function(JavaScriptConfirmDialogRequest request)? _onJavaScriptConfirm;
  Future<String> Function(JavaScriptTextInputDialogRequest request)? _onJavaScriptPrompt;

  void Function(ScrollPositionChange scrollPositionChange)? _onScrollPositionChangedCallback;

  static Future<void> enableDebugging(bool enabled) {
    return ohos_webview.WebView.setWebContentsDebuggingEnabled(enabled);
  }

  int get webViewIdentifier =>
      // ignore: invalid_use_of_visible_for_testing_member
      ohos_webview.WebView.api.instanceManager.getIdentifier(_webView)!;

  @override
  Future<void> loadFile(String absoluteFilePath) {
    return loadFileWithParams(OhosLoadFileParams(absoluteFilePath: absoluteFilePath));
  }

  @override
  Future<void> loadFileWithParams(LoadFileParams params) async {
    switch (params) {
      case final OhosLoadFileParams params:
        await Future.wait(<Future<void>>[
          _webView.settings.setAllowFileAccess(true),
          _webView.loadUrl(params.absoluteFilePath, params.headers),
        ]);

      default:
        await loadFileWithParams(OhosLoadFileParams.fromLoadFileParams(params));
    }
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    final String assetFilePath = await _flutterAssetManager.getAssetFilePathByName(key);
    final List<String> pathElements = assetFilePath.split('/');
    final String fileName = pathElements.removeLast();
    final List<String?> paths = await _flutterAssetManager.list(pathElements.join('/'));

    if (!paths.contains(fileName)) {
      throw ArgumentError('Asset for key "$key" not found.', 'key');
    }
    _webView.settings.setAllowFileAccess(true);
    final String url = "resources/rawfile/$assetFilePath";
    return _webView.loadUrl(url, <String, String>{});
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    return _webView.loadDataWithBaseUrl(baseUrl: baseUrl, data: html, mimeType: 'text/html', encoding: 'UTF-8');
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) {
    if (!params.uri.hasScheme) {
      throw ArgumentError('WebViewRequest#uri is required to have a scheme.');
    }
    switch (params.method) {
      case LoadRequestMethod.get:
        return _webView.loadUrl(params.uri.toString(), params.headers);
      case LoadRequestMethod.post:
        return _webView.postUrl(params.uri.toString(), params.body ?? Uint8List(0));
    }
    // 枚举来自其他包，可能随时新增取值；没有合理的默认行为，这里抛错提示调用方升级版本
    // ignore: dead_code
    throw UnimplementedError(
      'This version of `OhosWebViewController` currently has no '
      'implementation for HTTP method ${params.method.serialize()} in '
      'loadRequest.',
    );
  }

  @override
  Future<String?> currentUrl() => _webView.getUrl();

  @override
  Future<bool> canGoBack() => _webView.canGoBack();

  @override
  Future<bool> canGoForward() => _webView.canGoForward();

  @override
  Future<void> goBack() => _webView.goBack();

  @override
  Future<void> goForward() => _webView.goForward();

  @override
  Future<void> reload() => _webView.reload();

  @override
  Future<void> clearCache() => _webView.clearCache(true);

  @override
  Future<void> clearLocalStorage() => _ohosWebViewParams.ohosWebStorage.deleteAllData();

  @override
  Future<void> setPlatformNavigationDelegate(covariant OhosNavigationDelegate handler) async {
    _currentNavigationDelegate = handler;
    await Future.wait(<Future<void>>[
      handler.setOnLoadRequest(loadRequest),
      _webView.setWebViewClient(handler.ohosWebViewClient),
      _webView.setDownloadListener(handler.ohosDownloadListener),
    ]);
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    return _webView.evaluateJavascript(javaScript);
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    final String? result = await _webView.evaluateJavascript(javaScript);

    if (result == null) {
      return '';
    } else if (result == 'true') {
      return true;
    } else if (result == 'false') {
      return false;
    }

    return num.tryParse(result) ?? result;
  }

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams javaScriptChannelParams) {
    final OhosJavaScriptChannelParams ohosJavaScriptParams = javaScriptChannelParams is OhosJavaScriptChannelParams
        ? javaScriptChannelParams
        : OhosJavaScriptChannelParams.fromJavaScriptChannelParams(javaScriptChannelParams);

    // 同名 JS 通道已存在时先移除，再注册新通道
    if (_javaScriptChannelParams.containsKey(ohosJavaScriptParams.name)) {
      _webView.removeJavaScriptChannel(ohosJavaScriptParams._javaScriptChannel);
    }

    _javaScriptChannelParams[ohosJavaScriptParams.name] = ohosJavaScriptParams;

    return _webView.addJavaScriptChannel(ohosJavaScriptParams._javaScriptChannel);
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
    final OhosJavaScriptChannelParams? javaScriptChannelParams = _javaScriptChannelParams[javaScriptChannelName];
    if (javaScriptChannelParams == null) {
      return;
    }

    _javaScriptChannelParams.remove(javaScriptChannelName);
    return _webView.removeJavaScriptChannel(javaScriptChannelParams._javaScriptChannel);
  }

  @override
  Future<String?> getTitle() => _webView.getTitle();

  @override
  Future<void> scrollTo(int x, int y) => _webView.scrollTo(x, y);

  @override
  Future<void> scrollBy(int x, int y) => _webView.scrollBy(x, y);

  @override
  Future<Offset> getScrollPosition() {
    return _webView.getScrollPosition();
  }

  @override
  Future<void> setVerticalScrollBarEnabled(bool enabled) =>
      _webView.settings.setVerticalScrollBarAccessEnabled(enabled);

  @override
  Future<void> setHorizontalScrollBarEnabled(bool enabled) =>
      _webView.settings.setHorizontalScrollBarAccessEnabled(enabled);

  @override
  bool supportsSetScrollBarsEnabled() => true;

  @override
  Future<void> enableZoom(bool enabled) => _webView.settings.setSupportZoom(enabled);

  @override
  Future<void> setBackgroundColor(Color color) => _webView.settings.setBackgroundColor(color);

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) =>
      _webView.settings.setJavaScriptEnabled(javaScriptMode == JavaScriptMode.unrestricted);

  @override
  Future<void> setUserAgent(String? userAgent) => _webView.settings.setUserAgentString(userAgent);

  @override
  Future<void> setOnScrollPositionChange(
    void Function(ScrollPositionChange scrollPositionChange)? onScrollPositionChange,
  ) async {
    _onScrollPositionChangedCallback = onScrollPositionChange;
  }

  Future<void> setMediaPlaybackRequiresUserGesture(bool require) {
    return _webView.settings.setMediaPlaybackRequiresUserGesture(require);
  }

  Future<void> setTextZoom(int textZoom) => _webView.settings.setTextZoom(textZoom);

  Future<void> setOnShowFileSelector(Future<List<String>> Function(FileSelectorParams params)? onShowFileSelector) {
    _onShowFileSelectorCallback = onShowFileSelector;
    return _webChromeClient.setSynchronousReturnValueForOnShowFileChooser(onShowFileSelector != null);
  }

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {
    _onPermissionRequestCallback = onPermissionRequest;
  }

  Future<void> setGeolocationPermissionsPromptCallbacks({
    OnGeolocationPermissionsShowPrompt? onShowPrompt,
    OnGeolocationPermissionsHidePrompt? onHidePrompt,
  }) async {
    _onGeolocationPermissionsShowPrompt = onShowPrompt;
    _onGeolocationPermissionsHidePrompt = onHidePrompt;
  }

  Future<void> setCustomWidgetCallbacks({
    required OnShowCustomWidgetCallback? onShowCustomWidget,
    required OnHideCustomWidgetCallback? onHideCustomWidget,
  }) async {
    _onShowCustomWidgetCallback = onShowCustomWidget;
    _onHideCustomWidgetCallback = onHideCustomWidget;
  }

  @override
  Future<void> setOnConsoleMessage(void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage) async {
    _onConsoleLogCallback = onConsoleMessage;

    return _webChromeClient.setSynchronousReturnValueForOnConsoleMessage(_onConsoleLogCallback != null);
  }

  @override
  Future<String?> getUserAgent() => _webView.settings.getUserAgentString();

  @override
  Future<void> setOnJavaScriptAlertDialog(
    Future<void> Function(JavaScriptAlertDialogRequest request) onJavaScriptAlertDialog,
  ) async {
    _onJavaScriptAlert = onJavaScriptAlertDialog;
    return _webChromeClient.setSynchronousReturnValueForOnJsAlert(true);
  }

  @override
  Future<void> setOnJavaScriptConfirmDialog(
    Future<bool> Function(JavaScriptConfirmDialogRequest request) onJavaScriptConfirmDialog,
  ) async {
    _onJavaScriptConfirm = onJavaScriptConfirmDialog;
    return _webChromeClient.setSynchronousReturnValueForOnJsConfirm(true);
  }

  @override
  Future<void> setOnJavaScriptTextInputDialog(
    Future<String> Function(JavaScriptTextInputDialogRequest request) onJavaScriptTextInputDialog,
  ) async {
    _onJavaScriptPrompt = onJavaScriptTextInputDialog;
    return _webChromeClient.setSynchronousReturnValueForOnJsPrompt(true);
  }

  Future<void> setMixedContentMode(MixedContentMode mode) {
    final ohos_webview.MixedContentMode ohosMode = switch (mode) {
      MixedContentMode.alwaysAllow => ohos_webview.MixedContentMode.alwaysAllow,
      MixedContentMode.compatibilityMode => ohos_webview.MixedContentMode.compatibilityMode,
      MixedContentMode.neverAllow => ohos_webview.MixedContentMode.neverAllow,
    };
    return _webView.settings.setMixedContentMode(ohosMode);
  }

  @override
  Future<void> setOverScrollMode(WebViewOverScrollMode mode) {
    final ohos_webview.OverScrollMode ohosMode = switch (mode) {
      WebViewOverScrollMode.always => ohos_webview.OverScrollMode.always,
      WebViewOverScrollMode.ifContentScrolls => ohos_webview.OverScrollMode.never,
      WebViewOverScrollMode.never => ohos_webview.OverScrollMode.never,
    };
    return _webView.settings.setOverScrollMode(ohosMode);
  }

  Future<bool> isWebViewFeatureSupported(WebViewFeatureType featureType) {
    final String feature = switch (featureType) {
      WebViewFeatureType.paymentRequest => WebViewFeatureConstants.paymentRequest,
    };
    return ohos_webview.WebViewFeature.isFeatureSupported(feature);
  }

  Future<void> setPaymentRequestEnabled(bool enabled) {
    return ohos_webview.WebSettingsCompat.setPaymentRequestEnabled(_webView.settings, enabled);
  }
}

class OhosWebViewPermissionRequest extends PlatformWebViewPermissionRequest {
  const OhosWebViewPermissionRequest._({required super.types, required ohos_webview.PermissionRequest request})
    : _request = request;

  final ohos_webview.PermissionRequest _request;

  @override
  Future<void> grant() {
    return _request.grant(
      types.map<String>((WebViewPermissionResourceType type) {
        switch (type) {
          case WebViewPermissionResourceType.camera:
            return ohos_webview.PermissionRequest.videoCapture;
          case WebViewPermissionResourceType.microphone:
            return ohos_webview.PermissionRequest.audioCapture;
          case OhosWebViewPermissionResourceType.midiSysex:
            return ohos_webview.PermissionRequest.midiSysex;
          case OhosWebViewPermissionResourceType.protectedMediaId:
            return ohos_webview.PermissionRequest.protectedMediaId;
        }

        throw UnsupportedError('Resource of type `${type.name}` is not supported.');
      }).toList(),
    );
  }

  @override
  Future<void> deny() {
    return _request.deny();
  }
}

typedef OnGeolocationPermissionsShowPrompt =
    Future<GeolocationPermissionsResponse> Function(GeolocationPermissionsRequestParams request);

typedef OnGeolocationPermissionsHidePrompt = void Function();

typedef OnShowCustomWidgetCallback = void Function(Widget widget, void Function() onCustomWidgetHidden);

typedef OnHideCustomWidgetCallback = void Function();

@immutable
class GeolocationPermissionsRequestParams {
  const GeolocationPermissionsRequestParams({required this.origin});

  final String origin;
}

@immutable
class GeolocationPermissionsResponse {
  const GeolocationPermissionsResponse({required this.allow, required this.retain});

  final bool allow;

  final bool retain;
}

enum FileSelectorMode { open, openMultiple, save }

enum MixedContentMode { alwaysAllow, compatibilityMode, neverAllow }

enum WebViewFeatureType { paymentRequest }

@immutable
class FileSelectorParams {
  const FileSelectorParams({
    required this.isCaptureEnabled,
    required this.acceptTypes,
    this.filenameHint,
    required this.mode,
  });

  factory FileSelectorParams._fromFileChooserParams(ohos_webview.FileChooserParams params) {
    final FileSelectorMode mode;
    switch (params.mode) {
      case ohos_webview.FileChooserMode.open:
        mode = FileSelectorMode.open;
        break;
      case ohos_webview.FileChooserMode.openMultiple:
        mode = FileSelectorMode.openMultiple;
        break;
      case ohos_webview.FileChooserMode.save:
        mode = FileSelectorMode.save;
        break;
    }

    return FileSelectorParams(
      isCaptureEnabled: params.isCaptureEnabled,
      acceptTypes: params.acceptTypes,
      mode: mode,
      filenameHint: params.filenameHint,
    );
  }

  final bool isCaptureEnabled;

  final List<String> acceptTypes;

  final String? filenameHint;

  final FileSelectorMode mode;
}

@immutable
class OhosJavaScriptChannelParams extends JavaScriptChannelParams {
  OhosJavaScriptChannelParams({required super.name, required super.onMessageReceived})
    : assert(name.isNotEmpty),
      _javaScriptChannel = ohos_webview.JavaScriptChannel(
        name,
        postMessage: withWeakReferenceTo(onMessageReceived, (
          WeakReference<void Function(JavaScriptMessage)> weakReference,
        ) {
          return (String message) {
            if (weakReference.target != null) {
              weakReference.target!(JavaScriptMessage(message: message));
            }
          };
        }),
      );

  OhosJavaScriptChannelParams.fromJavaScriptChannelParams(JavaScriptChannelParams params)
    : this(name: params.name, onMessageReceived: params.onMessageReceived);

  final ohos_webview.JavaScriptChannel _javaScriptChannel;
}

@immutable
class OhosWebViewWidgetCreationParams extends PlatformWebViewWidgetCreationParams {
  const OhosWebViewWidgetCreationParams({
    super.key,
    required super.controller,
    super.layoutDirection,
    super.gestureRecognizers,
    this.displayWithHybridComposition = false,
    @visibleForTesting this.platformViewsServiceProxy = const PlatformViewsServiceProxy(),
  });

  OhosWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
    PlatformWebViewWidgetCreationParams params, {
    bool displayWithHybridComposition = false,
    @visibleForTesting PlatformViewsServiceProxy platformViewsServiceProxy = const PlatformViewsServiceProxy(),
  }) : this(
         key: params.key,
         controller: params.controller,
         layoutDirection: params.layoutDirection,
         gestureRecognizers: params.gestureRecognizers,
         displayWithHybridComposition: displayWithHybridComposition,
         platformViewsServiceProxy: platformViewsServiceProxy,
       );

  @visibleForTesting
  final PlatformViewsServiceProxy platformViewsServiceProxy;

  final bool displayWithHybridComposition;

  @override
  int get hashCode => Object.hash(controller, layoutDirection, displayWithHybridComposition, platformViewsServiceProxy);

  @override
  bool operator ==(Object other) {
    return other is OhosWebViewWidgetCreationParams &&
        controller == other.controller &&
        layoutDirection == other.layoutDirection &&
        displayWithHybridComposition == other.displayWithHybridComposition &&
        platformViewsServiceProxy == other.platformViewsServiceProxy;
  }
}

class OhosWebViewWidget extends PlatformWebViewWidget {
  OhosWebViewWidget(PlatformWebViewWidgetCreationParams params)
    : super.implementation(
        params is OhosWebViewWidgetCreationParams
            ? params
            : OhosWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(params),
      );

  OhosWebViewWidgetCreationParams get _ohosParams => params as OhosWebViewWidgetCreationParams;

  @override
  Widget build(BuildContext context) {
    _trySetDefaultOnShowCustomWidgetCallbacks(context);
    return PlatformViewLink(
      // 使用由 params 派生的默认 key，保证参数变化时 PlatformView 会重建
      key: _ohosParams.key ?? ValueKey<OhosWebViewWidgetCreationParams>(params as OhosWebViewWidgetCreationParams),
      viewType: 'plugins.flutter.io/webview',
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return OhosViewSurface(
          controller: controller as OhosViewController,
          gestureRecognizers: _ohosParams.gestureRecognizers,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return _initOhosView(params, displayWithHybridComposition: _ohosParams.displayWithHybridComposition)
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }

  OhosViewController _initOhosView(PlatformViewCreationParams params, {required bool displayWithHybridComposition}) {
    final int webViewIdentifier = (_ohosParams.controller as OhosWebViewController).webViewIdentifier;

    if (displayWithHybridComposition) {
      return _ohosParams.platformViewsServiceProxy.initExpensiveOhosView(
        id: params.id,
        viewType: 'plugins.flutter.io/webview',
        layoutDirection: _ohosParams.layoutDirection,
        creationParams: webViewIdentifier,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return _ohosParams.platformViewsServiceProxy.initSurfaceOhosView(
        id: params.id,
        viewType: 'plugins.flutter.io/webview',
        layoutDirection: _ohosParams.layoutDirection,
        creationParams: webViewIdentifier,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  }

  // 未设置自定义 View 回调时，使用默认实现处理
  void _trySetDefaultOnShowCustomWidgetCallbacks(BuildContext context) {
    final controller = _ohosParams.controller as OhosWebViewController;

    if (controller._onShowCustomWidgetCallback == null) {
      controller.setCustomWidgetCallbacks(
        onShowCustomWidget: (Widget widget, OnHideCustomWidgetCallback callback) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (BuildContext context) => widget, fullscreenDialog: true));
        },
        onHideCustomWidget: () {
          Navigator.of(context).pop();
        },
      );
    }
  }
}

@visibleForTesting
class OhosCustomViewWidget extends StatelessWidget {
  @visibleForTesting
  const OhosCustomViewWidget.private({
    super.key,
    required this.controller,
    required this.customView,
    @visibleForTesting this.platformViewsServiceProxy = const PlatformViewsServiceProxy(),
  });

  final ohos_webview.View customView;

  final PlatformWebViewController controller;

  @visibleForTesting
  final PlatformViewsServiceProxy platformViewsServiceProxy;

  OhosWebViewWidgetCreationParams get _ohosParams => controller.params as OhosWebViewWidgetCreationParams;

  @override
  Widget build(BuildContext context) {
    return OhosView(
      key: _ohosParams.key ?? ValueKey<OhosWebViewWidgetCreationParams>(_ohosParams),
      viewType: 'plugins.flutter.io/webview',
      layoutDirection: _ohosParams.layoutDirection,
      creationParams: (_ohosParams.controller as OhosWebViewController).webViewIdentifier,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: _ohosParams.gestureRecognizers,
    );
  }
}

typedef LoadRequestCallback = Future<void> Function(LoadRequestParams params);

@immutable
class OhosWebResourceError extends WebResourceError {
  OhosWebResourceError._({required super.errorCode, required super.description, super.isForMainFrame, super.url})
    : failingUrl = url,
      super(errorType: _errorCodeToErrorType(errorCode));

  @Deprecated('Please use `url`.')
  final String? failingUrl;

  static WebResourceErrorType? _errorCodeToErrorType(int errorCode) {
    switch (errorCode) {
      case ohos_webview.WebViewClient.errorAuthentication:
        return WebResourceErrorType.authentication;
      case ohos_webview.WebViewClient.errorBadUrl:
        return WebResourceErrorType.badUrl;
      case ohos_webview.WebViewClient.errorConnect:
        return WebResourceErrorType.connect;
      case ohos_webview.WebViewClient.errorFailedSslHandshake:
        return WebResourceErrorType.failedSslHandshake;
      case ohos_webview.WebViewClient.errorFile:
        return WebResourceErrorType.file;
      case ohos_webview.WebViewClient.errorFileNotFound:
        return WebResourceErrorType.fileNotFound;
      case ohos_webview.WebViewClient.errorHostLookup:
        return WebResourceErrorType.hostLookup;
      case ohos_webview.WebViewClient.errorIO:
        return WebResourceErrorType.io;
      case ohos_webview.WebViewClient.errorProxyAuthentication:
        return WebResourceErrorType.proxyAuthentication;
      case ohos_webview.WebViewClient.errorRedirectLoop:
        return WebResourceErrorType.redirectLoop;
      case ohos_webview.WebViewClient.errorTimeout:
        return WebResourceErrorType.timeout;
      case ohos_webview.WebViewClient.errorTooManyRequests:
        return WebResourceErrorType.tooManyRequests;
      case ohos_webview.WebViewClient.errorUnknown:
        return WebResourceErrorType.unknown;
      case ohos_webview.WebViewClient.errorUnsafeResource:
        return WebResourceErrorType.unsafeResource;
      case ohos_webview.WebViewClient.errorUnsupportedAuthScheme:
        return WebResourceErrorType.unsupportedAuthScheme;
      case ohos_webview.WebViewClient.errorUnsupportedScheme:
        return WebResourceErrorType.unsupportedScheme;
    }

    if (errorCode < 0) {
      return WebResourceErrorType.unknown;
    }

    throw ArgumentError('Could not find a WebResourceErrorType for errorCode: $errorCode');
  }
}

@immutable
class OhosNavigationDelegateCreationParams extends PlatformNavigationDelegateCreationParams {
  const OhosNavigationDelegateCreationParams._() : super();

  factory OhosNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
    // 保留占位参数，避免平台接口变更时签名不兼容
    // ignore: avoid_unused_constructor_parameters
    PlatformNavigationDelegateCreationParams params,
  ) {
    return const OhosNavigationDelegateCreationParams._();
  }
}

class OhosUrlChange extends UrlChange {
  const OhosUrlChange({required super.url, required this.isReload});

  final bool isReload;
}

class OhosNavigationDelegate extends PlatformNavigationDelegate {
  OhosNavigationDelegate(PlatformNavigationDelegateCreationParams params)
    : super.implementation(
        params is OhosNavigationDelegateCreationParams
            ? params
            : OhosNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(params),
      ) {
    final weakThis = WeakReference<OhosNavigationDelegate>(this);

    _webViewClient = ohos_webview.WebViewClient(
      onPageFinished: (ohos_webview.WebView webView, String url) {
        final PageEventCallback? callback = weakThis.target?._onPageFinished;
        if (callback != null) {
          callback(url);
        }
      },
      onPageStarted: (ohos_webview.WebView webView, String url) {
        final PageEventCallback? callback = weakThis.target?._onPageStarted;
        if (callback != null) {
          callback(url);
        }
      },
      onReceivedRequestError:
          (ohos_webview.WebView webView, ohos_webview.WebResourceRequest request, ohos_webview.WebResourceError error) {
            final WebResourceErrorCallback? callback = weakThis.target?._onWebResourceError;
            if (callback != null) {
              callback(
                OhosWebResourceError._(
                  errorCode: error.errorCode,
                  description: error.description,
                  url: request.url,
                  isForMainFrame: request.isForMainFrame,
                ),
              );
            }
          },
      requestLoading: (ohos_webview.WebView webView, ohos_webview.WebResourceRequest request) {
        weakThis.target?._handleNavigation(
          request.url,
          headers: request.requestHeaders,
          isForMainFrame: request.isForMainFrame,
        );
      },
      urlLoading: (ohos_webview.WebView webView, String url) {
        weakThis.target?._handleNavigation(url, isForMainFrame: true);
      },
      doUpdateVisitedHistory: (ohos_webview.WebView webView, String url, bool isReload) {
        final UrlChangeCallback? callback = weakThis.target?._onUrlChange;
        if (callback != null) {
          callback(OhosUrlChange(url: url, isReload: isReload));
        }
      },
      onReceivedHttpAuthRequest:
          (ohos_webview.WebView webView, ohos_webview.HttpAuthHandler httpAuthHandler, String host, String realm) {
            final void Function(HttpAuthRequest)? callback = weakThis.target?._onHttpAuthRequest;
            if (callback != null) {
              callback(
                HttpAuthRequest(
                  onProceed: (WebViewCredential credential) {
                    httpAuthHandler.proceed(credential.user, credential.password);
                  },
                  onCancel: () {
                    httpAuthHandler.cancel();
                  },
                  host: host,
                  realm: realm,
                ),
              );
            } else {
              httpAuthHandler.cancel();
            }
          },
      onReceivedHttpError:
          (ohos_webview.WebView webView, ohos_webview.WebResourceRequest request, ohos_webview.WebResourceError error) {
            final HttpResponseErrorCallback? httpErrorCallback = weakThis.target?._onHttpError;
            if (httpErrorCallback != null) {
              httpErrorCallback(
                HttpResponseError(
                  response: WebResourceResponse(
                    uri: Uri.parse(request.url),
                    statusCode: error.errorCode,
                    headers: <String, String>{},
                  ),
                  request: WebResourceRequest(uri: Uri.parse(request.url)),
                ),
              );
            }
          },
      onReceivedSslError:
          (
            ohos_webview.WebView webView,
            ohos_webview.SslErrorHandler handler,
            String url,
            String certificate,
            String description,
          ) async {
            final SslAuthErrorCallback? callback = weakThis.target?._onSslAuthError;

            if (callback != null) {
              callback(
                await OhosSslAuthError.fromNativeCallback(
                  handler: handler,
                  url: url,
                  certificateHint: certificate,
                  description: description,
                ),
              );
            } else {
              await handler.cancel();
            }
          },
    );

    _downloadListener = ohos_webview.DownloadListener(
      onDownloadStart: (String url, String userAgent, String contentDisposition, String mimetype, int contentLength) {
        if (weakThis.target != null) {
          weakThis.target?._handleNavigation(url, isForMainFrame: true);
        }
      },
    );
  }

  late final ohos_webview.WebChromeClient _webChromeClient = ohos_webview.WebChromeClient(
    onJsConfirm: (_, __) async => false,
    onShowFileChooser: (_, __) async => <String>[],
  );

  @Deprecated('This value is not used by `OhosWebViewController` and has no effect on the `WebView`.')
  ohos_webview.WebChromeClient get ohosWebChromeClient => _webChromeClient;

  late final ohos_webview.WebViewClient _webViewClient;

  ohos_webview.WebViewClient get ohosWebViewClient => _webViewClient;

  late final ohos_webview.DownloadListener _downloadListener;

  ohos_webview.DownloadListener get ohosDownloadListener => _downloadListener;

  PageEventCallback? _onPageFinished;
  PageEventCallback? _onPageStarted;
  ProgressCallback? _onProgress;
  WebResourceErrorCallback? _onWebResourceError;
  NavigationRequestCallback? _onNavigationRequest;
  LoadRequestCallback? _onLoadRequest;
  UrlChangeCallback? _onUrlChange;
  HttpAuthRequestCallback? _onHttpAuthRequest;
  HttpResponseErrorCallback? _onHttpError;
  SslAuthErrorCallback? _onSslAuthError;

  void _handleNavigation(
    String url, {
    required bool isForMainFrame,
    Map<String, String> headers = const <String, String>{},
  }) {
    final LoadRequestCallback? onLoadRequest = _onLoadRequest;
    final NavigationRequestCallback? onNavigationRequest = _onNavigationRequest;

    // 与 Android 保持一致：只拦截主框架导航，因为 loadUrl 无法加载子框架
    if (!isForMainFrame || onNavigationRequest == null || onLoadRequest == null) {
      return;
    }

    final FutureOr<NavigationDecision> returnValue = onNavigationRequest(
      NavigationRequest(url: url, isMainFrame: isForMainFrame),
    );

    if (returnValue is NavigationDecision && returnValue == NavigationDecision.navigate) {
      onLoadRequest(LoadRequestParams(uri: Uri.parse(url), headers: headers));
    } else if (returnValue is Future<NavigationDecision>) {
      returnValue.then((NavigationDecision shouldLoadUrl) {
        if (shouldLoadUrl == NavigationDecision.navigate) {
          onLoadRequest(LoadRequestParams(uri: Uri.parse(url), headers: headers));
        }
      });
    }
  }

  Future<void> setOnLoadRequest(LoadRequestCallback onLoadRequest) async {
    _onLoadRequest = onLoadRequest;
  }

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async {
    _onNavigationRequest = onNavigationRequest;
    return _webViewClient.setSynchronousReturnValueForShouldOverrideUrlLoading(true);
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    _onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    _onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    _onProgress = onProgress;
  }

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async {
    _onWebResourceError = onWebResourceError;
  }

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {
    _onUrlChange = onUrlChange;
  }

  @override
  Future<void> setOnHttpAuthRequest(HttpAuthRequestCallback onHttpAuthRequest) async {
    _onHttpAuthRequest = onHttpAuthRequest;
  }

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {
    _onHttpError = onHttpError;
  }

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {
    _onSslAuthError = onSslAuthError;
  }
}
