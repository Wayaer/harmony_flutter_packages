// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webview_flutter_harmonyos/src/ohos_webview.dart' as ohos_webview;

class OhosWebViewProxy {
  const OhosWebViewProxy({
    this.createOhosWebView = ohos_webview.WebView.new,
    this.createOhosWebChromeClient = ohos_webview.WebChromeClient.new,
    this.createOhosWebViewClient = ohos_webview.WebViewClient.new,
    this.createFlutterAssetManager = ohos_webview.FlutterAssetManager.new,
    this.createJavaScriptChannel = ohos_webview.JavaScriptChannel.new,
    this.createDownloadListener = ohos_webview.DownloadListener.new,
  });

  final ohos_webview.WebView Function({void Function(int left, int top, int oldLeft, int oldTop)? onScrollChanged})
  createOhosWebView;

  final ohos_webview.WebChromeClient Function({
    void Function(ohos_webview.WebView webView, int progress)? onProgressChanged,
    Future<List<String>> Function(ohos_webview.WebView webView, ohos_webview.FileChooserParams params)?
    onShowFileChooser,
    void Function(ohos_webview.WebChromeClient instance, ohos_webview.PermissionRequest request)? onPermissionRequest,
    Future<void> Function(String origin, ohos_webview.GeolocationPermissionsCallback callback)?
    onGeolocationPermissionsShowPrompt,
    void Function(ohos_webview.WebChromeClient instance)? onGeolocationPermissionsHidePrompt,
    void Function(ohos_webview.WebChromeClient instance, ohos_webview.ConsoleMessage message)? onConsoleMessage,
    void Function(
      ohos_webview.WebChromeClient instance,
      ohos_webview.View view,
      ohos_webview.CustomViewCallback callback,
    )?
    onShowCustomView,
    void Function(ohos_webview.WebChromeClient instance)? onHideCustomView,
    Future<void> Function(String url, String message)? onJsAlert,
    Future<bool> Function(String url, String message)? onJsConfirm,
    Future<String> Function(String url, String message, String defaultValue)? onJsPrompt,
  })
  createOhosWebChromeClient;

  final ohos_webview.WebViewClient Function({
    void Function(ohos_webview.WebView webView, String url)? onPageStarted,
    void Function(ohos_webview.WebView webView, String url)? onPageFinished,
    void Function(
      ohos_webview.WebView webView,
      ohos_webview.WebResourceRequest request,
      ohos_webview.WebResourceError error,
    )?
    onReceivedRequestError,
    @Deprecated('Only called on Ohos version < 23.')
    void Function(ohos_webview.WebView webView, int errorCode, String description, String failingUrl)? onReceivedError,
    void Function(ohos_webview.WebView webView, ohos_webview.WebResourceRequest request)? requestLoading,
    void Function(ohos_webview.WebView webView, String url)? urlLoading,
    void Function(ohos_webview.WebView webView, String url, bool isReload)? doUpdateVisitedHistory,
    void Function(ohos_webview.WebView webView, ohos_webview.HttpAuthHandler handler, String host, String realm)?
    onReceivedHttpAuthRequest,
    void Function(
      ohos_webview.WebView webView,
      ohos_webview.WebResourceRequest request,
      ohos_webview.WebResourceError error,
    )?
    onReceivedHttpError,
    void Function(
      ohos_webview.WebView webView,
      ohos_webview.SslErrorHandler handler,
      String url,
      String certificate,
      String description,
    )?
    onReceivedSslError,
  })
  createOhosWebViewClient;

  final ohos_webview.FlutterAssetManager Function() createFlutterAssetManager;

  final ohos_webview.JavaScriptChannel Function(String channelName, {required void Function(String) postMessage})
  createJavaScriptChannel;

  final ohos_webview.DownloadListener Function({
    required void Function(String url, String userAgent, String contentDisposition, String mimetype, int contentLength)
    onDownloadStart,
  })
  createDownloadListener;

  Future<void> setWebContentsDebuggingEnabled(bool enabled) {
    return ohos_webview.WebView.setWebContentsDebuggingEnabled(enabled);
  }
}
