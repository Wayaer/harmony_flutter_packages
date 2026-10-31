// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on WebViewHostApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView'
import { DVModel, DVModelParameters } from '@ohos/flutter_ohos/src/main/ets/view/DynamicView/dynamicView'
import { Result, WebViewHostApi, WebViewPoint, HttpAuthHandler, SslErrorHandler } from './GeneratedOhosWebView'
import web_webview from '@ohos.web.webview'
import { WebBuilder, OhosWebView } from './OhosWebView'
import { createDVModelFromJson } from '@ohos/flutter_ohos/src/main/ets/view/DynamicView/dynamicViewJson'
import { DVModelJson } from "./DynamicUtils"
import { InstanceManager } from './InstanceManager'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import common from '@ohos.app.ability.common'
import { WebChromeClient } from './WebChromeClientHostApiImpl'
import { WebViewClient } from './WebViewClientHostApiImpl'
import { WebSettings } from './WebSettingsHostApiImpl'
import { DynamicUtils } from "./DynamicUtils"
import { DownloadListener } from './DownloadListenerFlutterApiImpl'
import { DisplayListenerProxy } from './DisplayListenerProxy'
import { JavaScriptChannel } from './JavaScriptChannel'
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { WebViewFlutterApiImpl } from './WebViewFlutterApiImpl.ets'
import window from '@ohos.window'
import display from '@ohos.display'

const TAG: string = "WebViewHostApiImpl";

function arkWebSslErrorNumericCode(raw: ESObject): number | undefined {
  if (raw === undefined || raw === null) {
    return undefined;
  }
  if (typeof raw === 'number') {
    return raw;
  }
  const n = Number(raw);
  return Number.isNaN(n) ? undefined : n;
}

function arkWebSslErrorCodeToDescription(code: number): string {
  switch (code) {
    case 0:
      return 'A generic SSL error occurred.';
    case 1:
      return 'Hostname mismatch.';
    case 2:
      return 'The certificate date is invalid.';
    case 3:
      return 'The certificate authority is not trusted.';
    default:
      return `SSL certificate validation failed (error code ${code}).`;
  }
}

export declare class PlatformViewVisibleAreaEventOptions {
  enable: boolean
  ratios: Array<number>
  expectedUpdateInterval: number
  onInactiveThreshold: number
  onActiveThreshold: number
}

export class WebViewHostApiImpl extends WebViewHostApi {
  private instanceManager: InstanceManager;

  private webViewProxy: WebViewProxy;

  private binaryMessenger: BinaryMessenger;

  private context: common.Context;
  private api?: WebViewFlutterApiImpl;

  constructor(
    instanceManager: InstanceManager,
    webViewProxy: WebViewProxy,
    binaryMessenger: BinaryMessenger,
    context: common.Context
  ) {
    super();
    this.instanceManager = instanceManager;
    this.webViewProxy = webViewProxy;
    this.binaryMessenger = binaryMessenger;
    this.context = context;
  }

  setContext(context: common.Context): void {
    this.context = context;
  }

  create(instanceId: number): void {
    let displayProxy: DisplayListenerProxy = new DisplayListenerProxy();
    displayProxy.onPreWebViewInitialization();
    const webView: WebViewPlatformView = this.webViewProxy.createWebView(this.binaryMessenger, this.instanceManager);
    displayProxy.onPostWebViewInitialization();
    this.instanceManager.addDartCreatedInstance(webView, instanceId);
  }

  loadData(instanceId: number, data: string, mimeType: string, encoding: string): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.getController().loadData(data, mimeType, encoding, " ", " ");
  }

  async loadDataWithBaseUrl(
    instanceId: number, baseUrl: string, data: string, mimeType: string, encoding: string, historyUrl: string
  ): Promise<void> {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    await webView.waitControllerAttached();
    try {
      // baseUrl 为空时默认使用 resource://rawfile/，以解决 a 标签锚点无效的问题
      webView.getController().loadData(data, mimeType, encoding, baseUrl == null || baseUrl.trim().length === 0 ? "resource://rawfile/" : baseUrl , historyUrl == null ? " " : historyUrl);
    } catch (err) {
      Log.e(TAG, "loadDataWithBaseUrl err = " + err);
    }
  }

  async loadUrl(instanceId: number, url: string, headers: Map<string, string>): Promise<void> {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    await webView.waitControllerAttached();
    try {
      if (url.startsWith("resources/rawfile/")) {
        try {
          webView.getController().setPathAllowingUniversalAccess([
            getContext().resourceDir
          ])
        } catch (err) {
          Log.e(TAG, "setPathAllowingUniversalAccess err = " + err);
        }
        webView.getController().loadUrl($rawfile(url.replace("resources/rawfile/","")), this.toWebHeaders(headers));
      }else {
        webView.getController().loadUrl(url, this.toWebHeaders(headers));
      }
      webView.setUrl(webView.getController().getUrl());
    } catch (err) {
      Log.e(TAG, "loadUrl err = " + err);
    }
  }

  toWebHeaders(headers: Map<string, string>): Array<web_webview.WebHeader> {
    let result: Array<web_webview.WebHeader> = new Array;
    if (headers == null || headers.size == 0) {
      return result;
    }
    for (let arr of headers) {
      let key = arr[0];
      let value = arr[1];
      let header: web_webview.WebHeader = { headerKey: key, headerValue: value };
      result.push(header);
    }
    return result;
  }

  async postUrl(instanceId: number, url: string, data: Uint8Array):  Promise<void> {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    await webView.waitControllerAttached();
    try {
      webView.getController().postUrl(url,data.buffer);
    } catch (err) {
      Log.e(TAG, "postUrl err = " + err);
    }
  }

  async getUrl(instanceId: number): Promise<string> {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    await webView.waitControllerAttached();
    return webView.getController().getUrl();
  }

  canGoBack(instanceId: number): boolean {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    return webView.getController().accessBackward();
  }

  canGoForward(instanceId: number): boolean {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    return webView.getController().accessForward();
  }

  goBack(instanceId: number): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.getController().backward();
  }

  goForward(instanceId: number): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.getController().forward();
  }

  reload(instanceId: number): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.getController().refresh();
  }

  clearCache(instanceId: number, includeDiskFiles: boolean): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.waitControllerAttached().then(() => {
      webView.getController().removeCache(includeDiskFiles);
    }).catch(() => {
    });
  }

  evaluateJavascript(instanceId: number, javascriptString: string, result: Result<string>): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.getController().runJavaScript(javascriptString)
      .then(
        scriptResult => {
          result.success(scriptResult);
        }
      )
      .catch(
        (error: ESObject) => {
          result.error(error);
        }
      )
  }

  getTitle(instanceId: number): string {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    return webView.getController().getTitle();
  }

  scrollTo(instanceId: number, x: number, y: number): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.waitControllerAttached().then(() => {
      webView.getController().scrollTo(x, y);
      webView.setScrollPosition(x, y);
    });
  }

  scrollBy(instanceId: number, x: number, y: number): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.waitControllerAttached().then(() => {
      const currentX = webView.getScrollX();
      const currentY = webView.getScrollY();
      webView.getController().scrollBy(x, y);
      webView.setScrollPosition(currentX + x, currentY + y);
    });
  }

  getScrollX(instanceId: number): number {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    return webView.getScrollX();
  }

  getScrollY(instanceId: number): number {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    return webView.getScrollY()
  }

  getScrollPosition(instanceId: number): WebViewPoint {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    return WebViewPoint.Builder()
      .setX(webView.getScrollX())
      .setY(webView.getScrollY())
      .build();
  }

  setWebContentsDebuggingEnabled(enabled: boolean): void {
    this.webViewProxy.setWebContentsDebuggingEnabled(enabled);
  }

  setWebViewClient(instanceId: number, webViewClientInstanceId: number) {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.setWebViewClient(this.instanceManager.getInstance(webViewClientInstanceId));
  }

  async addJavaScriptChannel(instanceId: number, javaScriptChannelInstanceId: number): Promise<void> {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    const javaScriptChannel: JavaScriptChannel = this.instanceManager.getInstance(javaScriptChannelInstanceId);
    await webView.waitControllerAttached();
    try {
      webView.addJavaScriptChannel(javaScriptChannel);
      webView.getController().registerJavaScriptProxy(
        {
          postMessage: (message: ESObject) => {
            javaScriptChannel.postMessage(String(message))
          },
        },
        javaScriptChannel.getJavaScriptChannelName(),
        ["postMessage"]
      )
      // 注册的 JS 代理需 refresh 后才对当前页面生效
      webView.getController().refresh()
    } catch (err) {
      Log.e(TAG, "addJavaScriptChannel err = " + err);
    }
  }

  removeJavaScriptChannel(instanceId: number, javaScriptChannelInstanceId: number): void {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    const javaScriptChannel: JavaScriptChannel = this.instanceManager.getInstance(javaScriptChannelInstanceId);
    webView.removeJavaScriptChannel(javaScriptChannel.getJavaScriptChannelName());
    webView.getController().deleteJavaScriptRegister(javaScriptChannel.getJavaScriptChannelName());
    this.instanceManager.remove(javaScriptChannelInstanceId);
  }

  setDownloadListener(instanceId: number, listenerInstanceId: number) {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.setDownloadListener(this.instanceManager.getInstance(listenerInstanceId));
  }

  setWebChromeClient(instanceId: number, clientInstanceId: number) {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    webView.setWebChromeClient(this.instanceManager.getInstance(clientInstanceId));
  }

  getInstanceManager(): InstanceManager {
    return this.instanceManager;
  }

  setApi(api: WebViewFlutterApiImpl) {
    this.api = api;
  }
}

export class WebViewPlatformView extends PlatformView {

  private WebCookieManager: web_webview.WebCookieManager = new web_webview.WebCookieManager();

  private controller: web_webview.WebviewController = new web_webview.WebviewController();

  private tempUrl: string = "";

  private downloadListener: DownloadListener = {} as ESObject;

  private webChromeClient: WebChromeClient | null = null;

  private webViewClint: WebViewClient | null = null;

  private webSettings: WebSettings | null = null;

  private dialogController: CustomDialogController | null = null;

  private scrollX: number = 0;

  private scrollY: number = 0;

  private returnValueForShouldOverrideUrlLoading: boolean = false;

  private controllerAttached: boolean = false;

  private onDisposeCallback?: () => void;

  private rotation: number = 0;
  
  userAgentString: string = '';
 	  	 
 	isWebviewBinding: boolean = false;

  private webViewFlutterApi: WebViewFlutterApiImpl;

  private javaScriptChannels: Map<string, JavaScriptChannel> = new Map();

  private visibleAreaEventEnable: boolean = true;

  private visibleAreaEventRatios: Array<number> = [0, 0.1, 0.2, 0.5, 0.8, 1];

  private visibleAreaEventExpectedUpdateInterval: number = 1;

  private visibleAreaEventInactiveThreshold: number = 0.0;

  private visibleAreaEventActiveThreshold: number = 0.1;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    super();
    this.webViewFlutterApi = new WebViewFlutterApiImpl(binaryMessenger, instanceManager);
  }

  onDownloadStart = (event: ESObject) => {
    if (this.downloadListener && this.downloadListener.onDownloadStart) {
      this.downloadListener.onDownloadStart(
        event.url,
        event.userAgent,
        event.contentDisposition,
        event.mimetype,
        event.contentLength
      )
    }
  }

  onPageBegin = (event: ESObject) => {
    if (this.webViewClint) {
      this.webViewClint.onPageStarted(this, event.url);
    }
  }

  onPageEnd = (event: ESObject) => {
    if (this.webViewClint) {
      this.webViewClint.onPageFinished(this, event.url);
    }
  }

  onErrorReceive = (event: ESObject) => {
    if (this.webViewClint) {
      this.webViewClint.onReceivedError(this, event.request, event.error);
    }
  }

  onHttpErrorReceive = (event: ESObject) => {
    if (this.webViewClint) {
      this.webViewClint.onReceivedHttpError(this, event.request, event.response);
    }
  }

  onOverrideUrlLoading = (request: WebResourceRequest) => {
    Log.i(TAG, "onOverrideUrlLoading request = " + JSON.stringify(request))
    if(request.getRequestUrl() == 'loaded:///'){
      return true;
    }

    if (this.webViewClint) {
      return this.webViewClint.shouldOverrideUrlLoading(this, request);
    }

    return false;
  }

  onRefreshAccessedHistory = (event: ESObject) => {
    if (this.webViewClint) {
      this.webViewClint.doUpdateVisitedHistory(this, event.url, event.isRefreshed);
    }
  }

  onHttpAuthRequest = (event: ESObject): boolean => {
    Log.i(TAG, "onHttpAuthRequest host=" + event.host + " realm=" + event.realm);
    if (this.webViewClint) {
      const wrappedHandler = new OhosHttpAuthHandler(event.handler);
      this.webViewClint.onReceivedHttpAuthRequest(this, wrappedHandler, event.host, event.realm);
      return true;
    }
    return false;
  }

  onSslErrorReceive = (event: ESObject): void => {
    if (!event || !event.handler) {
      Log.e(TAG, "onSslErrorReceive: missing event or handler");
      return;
    }
    let urlStr = "";
    try {
      if (event.originalUrl !== undefined && event.originalUrl !== null) {
        urlStr = `${event.originalUrl}`;
      } else if (event.url !== undefined && event.url !== null) {
        urlStr = `${event.url}`;
      }
    } catch (err) {
      Log.e(TAG, "onSslErrorReceive url extract err = " + err);
    }

    if (!urlStr || urlStr.trim().length === 0) {
      try {
        const fromCtrl = this.controller.getUrl();
        if (fromCtrl !== undefined && fromCtrl !== null && `${fromCtrl}`.trim().length > 0) {
          urlStr = `${fromCtrl}`;
        }
      } catch (_) {
      }
    }
    if (!urlStr || urlStr.trim().length === 0) {
      urlStr = this.getUrl() ?? "";
    }

    let description = "SSL certificate validation failed.";
    try {
      const code = arkWebSslErrorNumericCode(event.error ?? event.sslError);
      if (code !== undefined) {
        description = arkWebSslErrorCodeToDescription(code);
      } else if (event.error !== undefined && event.error !== null) {
        description = `SSL error: ${event.error}`;
      }
    } catch (errDesc) {
      Log.e(TAG, "onSslErrorReceive description extract err = " + errDesc);
    }

    let certStr = "";
    try {
      if (event.certIssuer !== undefined && event.certIssuer !== null) {
        certStr = `${event.certIssuer}`;
      }
    } catch (errCert) {
      Log.e(TAG, "onSslErrorReceive cert extract err = " + errCert);
    }

    if (this.webViewClint) {
      try {
        const wrappedHandler = new OhosSslErrorHandler(event.handler as ESObject);
        this.webViewClint.onReceivedSslError(this, wrappedHandler, urlStr, certStr, description);
      } catch (errForward) {
        Log.e(TAG, "onSslErrorReceive forward err = " + errForward);
        new OhosSslErrorHandler(event.handler as ESObject).cancel();
      }
    } else {
      new OhosSslErrorHandler(event.handler as ESObject).cancel();
    }
  }

  onProgressChange = (event: ESObject) => {
    if (this.webChromeClient) {
      this.webChromeClient.onProgressChanged(this, event.newProgress)
    }
  }

  onGeolocationShow = (event: ESObject) => {
    if (this.webChromeClient) {
      this.webChromeClient.onGeolocationPermissionsShowPrompt(event.origin, event.geolocation)
    }
  }

  onGeolocationHide = () => {
    if (this.webChromeClient) {
      this.webChromeClient.onGeolocationPermissionsHidePrompt();
    }
  }

  onShowFileSelector = (event: ESObject) => {
    if (this.webChromeClient) {
      return this.webChromeClient.onShowFileChooser(this, event.result, event.fileSelector)
    }
    return false;
  }

  onPermissionRequest = (event: ESObject) => {
    if (this.webChromeClient) {
      this.webChromeClient.onPermissionRequest(event.request);
    }
  }

  onConsoleMessage = (event: ESObject) => {
    let message:ConsoleMessage = event.message;
    if (this.webChromeClient) {
        this.webChromeClient.onConsoleMessage(event.message);
    } else {
      Log.d(TAG, "logLevel: " + message.getMessageLevel() + " "+ message.getMessage());
    }
    return true;
  }

  onWindowNew = (event: ESObject) => {
    if (this.webChromeClient) {
      this.webChromeClient.onCreateWindow(this, event.isAlert, event.isUserTrigger, event.handler)
    }
  }

  onWindowExit = () => {
    if (this.dialogController) {
      this.dialogController.close();
    }
  }

  onScroll = (event: ESObject) => {
    this.webViewFlutterApi.onScrollChanged(this, event.xOffset, event.yOffset, this.scrollX, this.scrollY, {reply: () => {}})
    this.scrollX = event.xOffset;
    this.scrollY = event.yOffset;
  }

  aboutToAppear() {
    this.isWebviewBinding = true;
  }

  onControllerAttached = () => {
    Log.d(TAG, "onControllerAttached");
    if (this.userAgentString) {
      this.setCustomUserAgent(this.userAgentString);
      this.controller.refresh();
    }
    this.controllerAttached = true;
    this.reRegisterJavaScriptChannels();
  }

  aboutToDisappear() {
    this.isWebviewBinding = false;
  }

  setOnDisposeCallback(callback: () => void) {
    this.onDisposeCallback = callback;
  }

  onJsAlert = (event: ESObject): boolean => {
    if (this.webChromeClient && event) {
      return this.webChromeClient.onJsAlert(this, event.url, event.message, event.result);
    }
    return true;
  }

  onJsConfirm = (event: ESObject): boolean => {
    if (this.webChromeClient && event) {
      return this.webChromeClient.onJsConfirm(this, event.url, event.message, event.result);
    }
    return true;
  }

  onJsPrompt = (event: ESObject): boolean => {
    if (this.webChromeClient && event) {
      return this.webChromeClient.onJsPrompt(this, event.url, event.message, event.value, event.result);
    }
    return true;
  }

  onFullScreenEnter = (event: ESObject) => {
    let context = getContext(this) as common.UIAbilityContext;
    let windowClass = context.windowStage.getMainWindowSync();
    windowClass.setWindowSystemBarEnable([]);
    this.rotation = windowClass.getPreferredOrientation();
    let isAllowFullScreenRotate = this.getWebSettings()?.getAllowFullScreenRotate();
    if (isAllowFullScreenRotate) {
      windowClass.setPreferredOrientation(window.Orientation.LANDSCAPE);
    }
  }

  onFullScreenExit = () => {
    let context = getContext(this) as common.UIAbilityContext;
    let windowClass = context.windowStage.getMainWindowSync();
    windowClass.setWindowSystemBarEnable(['status', 'navigation']);
    windowClass.setPreferredOrientation(this.rotation);
    this.reRegisterJavaScriptChannels();
  }

  getType(): string {
    return 'web';
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(WebBuilder);
  }

  dispose(): void {
    this.controller.stopAllMedia();
    this.onDisposeCallback && this.onDisposeCallback();
  }

  getPlatformViewVisibleAreaEventOptions(): PlatformViewVisibleAreaEventOptions {
    return {
      enable: this.visibleAreaEventEnable,
      ratios: this.visibleAreaEventRatios,
      expectedUpdateInterval: this.visibleAreaEventExpectedUpdateInterval,
      onInactiveThreshold : this.visibleAreaEventInactiveThreshold,
      onActiveThreshold : this.visibleAreaEventActiveThreshold
    } as PlatformViewVisibleAreaEventOptions;
  }

  onInactive(): void {
    this.controller.onInactive();
  }

  onActive(): void {
    this.controller.onActive();
  }

  getController(): web_webview.WebviewController {
    return this.controller;
  }

  setCustomUserAgent(userAgentString: string) {
    this.userAgentString = userAgentString;
    this.controller.setCustomUserAgent(userAgentString);
  }

  setUrl(url: string): void {
    this.tempUrl = url;
  }

  getUrl(): string {
    return this.tempUrl;
  }

  getWebCookieManager(): web_webview.WebCookieManager {
    return this.WebCookieManager
  }

  setDownloadListener(listener: DownloadListener) {
    this.downloadListener = listener;
  }

  setWebViewClient(webViewClient: WebViewClient) {
    this.webViewClint = webViewClient;
  }

  setWebChromeClient(webChromeClient: WebChromeClient) {
    this.webChromeClient = webChromeClient;
  }

  setDialogController(dialogController: CustomDialogController) {
    this.dialogController = dialogController;
  }

  getDialogController(): CustomDialogController | null {
    return this.dialogController;
  }

  getWebSettings(): WebSettings {
    if (this.webSettings == null) {
      this.webSettings = new WebSettingsImpl(this);
    }
    return this.webSettings!;
  }

  getScrollX(): number {
    return this.scrollX;
  }

  getScrollY(): number {
    return this.scrollY;
  }

  setScrollPosition(x: number, y: number): void {
    this.scrollX = x;
    this.scrollY = y;
    this.webViewFlutterApi.onScrollChanged(this, x, y, this.scrollX, this.scrollY, {reply: () => {}});
  }

  setReturnValueForShouldOverrideUrlLoading(value: boolean) {
    this.returnValueForShouldOverrideUrlLoading = value;
  }

  async waitControllerAttached() {
    if (!this.controllerAttached) {
      await this.checkControllerAttached()
    }
  }

  checkControllerAttached(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        let intervalId = setInterval(() => {
          if (this.controllerAttached) {
            clearInterval(intervalId)
            resolve()
          }
        }, 20)
      } catch (err) {
        reject()
      }
    })
  }

  addJavaScriptChannel(channel: JavaScriptChannel) {
    this.javaScriptChannels.set(channel.getJavaScriptChannelName(), channel);
  }

  removeJavaScriptChannel(channelName: string) {
    this.javaScriptChannels.delete(channelName);
  }

  reRegisterJavaScriptChannels() {
    if (this.javaScriptChannels.size === 0) {
      return;
    }
    try {
      this.javaScriptChannels.forEach((channel: JavaScriptChannel, channelName: string) => {
        this.controller.registerJavaScriptProxy(
          {
            postMessage: (message: string) => {
              channel.postMessage(message)
            },
          },
          channelName,
          ["postMessage"]
        )
      })
      this.controller.refresh()
    } catch (err) {
      Log.e(TAG, "reRegisterJavaScriptChannels err = " + err);
    }
  }

}

export class WebViewProxy {
  createWebView(binaryMessenger:BinaryMessenger, instanceManager:InstanceManager): WebViewPlatformView {
    return new WebViewPlatformView(binaryMessenger, instanceManager);
  }

  setWebContentsDebuggingEnabled(enabled: boolean): void {
    web_webview.WebviewController.setWebDebuggingAccess(enabled);
  }
}

class WebSettingsImpl implements WebSettings {
  private webView: WebViewPlatformView;
  private defaultUserAgent: string = '';
  params: DVModelParameters = new DVModelParameters;
  domStorageAccess: boolean = false;
  allowWindowOpenMethod : boolean = false;
  multiWindowAccess : boolean = false;
  multiWindowAccessCallback?: (support: boolean) => void;
  backgroundColor : string = "";
  javaScriptAccess : boolean = false;
  mediaPlayGestureAccess : boolean = false;
  zoomAccess : boolean = true;
  overviewModeAccess : boolean = false;
  wideViewModeAccess: boolean = false;
  fileAccess : boolean = true;
  textZoomRatio : number = 0;
  textZoomRatioCallback?: (ratio: number) => void;
  isAllowFullScreenRotate: boolean = false;
  paymentRequestEnabled: boolean = false;
  mixedMode: number = 0;
  overScrollMode: number = 0;
  verticalScrollBarAccess: boolean = true;
  horizontalScrollBarAccess: boolean = true;
  verticalScrollBarAccessCallback?: (enabled: boolean) => void;
  horizontalScrollBarAccessCallback?: (enabled: boolean) => void;

  constructor(webView: WebViewPlatformView) {
    this.webView = webView;
  }

  setDomStorageEnabled(flag: boolean) {
    this.domStorageAccess = flag;
  }

  getDomStorageEnabled() : boolean{
    return this.domStorageAccess;
  }

  setJavaScriptCanOpenWindowsAutomatically(flag: boolean) {
    this.allowWindowOpenMethod = flag;
  }

  getJavaScriptCanOpenWindowsAutomatically() : boolean{
    return this.allowWindowOpenMethod;
  }

  setSupportMultipleWindows(support: boolean) {
    this.multiWindowAccess = support;
    this.multiWindowAccessCallback && this.multiWindowAccessCallback(support);
  }

  getSupportMultipleWindows()  : boolean{
    return this.multiWindowAccess;
  }

  onSupportMultipleWindowsChanged(callback: (support: boolean) => void): void {
    this.multiWindowAccessCallback = callback;
  }

  setBackgroundColor(color: number) {
    // number 无法表示透明度，需转成 string
    let colorStr = `#${color.toString(16).padStart(8, '0')}`;
    this.backgroundColor = colorStr;
  }

  getBackgroundColor() : string{
    return this.backgroundColor;
  }

  setJavaScriptEnabled(flag: boolean) {
    this.javaScriptAccess = flag;
  }

  getJavaScriptEnabled() : boolean {
    return this.javaScriptAccess;
  }

  async setUserAgentString(userAgentString: string) {
    await this.webView.waitControllerAttached();
    this.webView.setCustomUserAgent(userAgentString);
  }

  setMediaPlaybackRequiresUserGesture(require: boolean) {
    this.mediaPlayGestureAccess = require;
  }

  getMediaPlaybackRequiresUserGesture() : boolean{
    return this.mediaPlayGestureAccess;
  }

  setSupportZoom(support: boolean) {
    this.zoomAccess = support;
  }

  getSupportZoom() : boolean{
    return this.zoomAccess;
  }

  setLoadWithOverviewMode(overview: boolean) {
    this.overviewModeAccess = overview;
  }

  getLoadWithOverviewMode() : boolean {
    return this.overviewModeAccess;
  }

  setUseWideViewPort(use: boolean) {
    this.wideViewModeAccess = use;
  }

  getUseWideViewPort() : boolean {
    return this.wideViewModeAccess;
  }

  setDisplayZoomControls(enabled: boolean) {
  }

  setBuiltInZoomControls(enabled: boolean) {
  }

  setAllowFileAccess(enabled: boolean) {
    this.fileAccess = enabled;
  }

  getAllowFileAccess() : boolean {
    return this.fileAccess;
  }

  setTextZoom(textZoom: number) {
    this.textZoomRatio = textZoom;
    this.textZoomRatioCallback && this.textZoomRatioCallback(textZoom);
  }

  async getUserAgentString(): Promise<string> {
    try {
      await this.webView.waitControllerAttached();
    } catch(err) {
      Log.e(TAG, "getUserAgentString err = " + err)
    }
    if (this.webView.userAgentString) {
      return this.webView.userAgentString;
    }

    if (this.webView.isWebviewBinding) {
      return this.webView.getController().getCustomUserAgent();
    }

    if (this.defaultUserAgent) {
      return this.defaultUserAgent;
    }

    // 整个应用只需初始化一次 WebEngine
    web_webview.WebviewController.initializeWebEngine();
    this.defaultUserAgent = web_webview.WebviewController.getDefaultUserAgent();

    return this.defaultUserAgent;
  }

  getTextZoom() : number{
    return this.textZoomRatio;
  }

  onTextZoomChanged(callback: (ratio: number) => void): void {
    this.textZoomRatioCallback = callback;
  }

  setAllowFullScreenRotate(enabled: boolean) {
    this.isAllowFullScreenRotate = enabled;
  }

  getAllowFullScreenRotate() : boolean {
    return this.isAllowFullScreenRotate;
  }

  setPaymentRequestEnabled(enabled: boolean) {
    this.paymentRequestEnabled = enabled;
  }

  setMixedContentMode(mode: number) {
    this.mixedMode = mode;
  }

  getMixedMode(): number {
    return this.mixedMode;
  }

  setOverScrollMode(mode: number) {
    this.overScrollMode = mode;
  }

  getOverScrollMode(): number {
    return this.overScrollMode;
  }

  setVerticalScrollBarAccessEnabled(enabled: boolean) {
    this.verticalScrollBarAccess = enabled;
    this.verticalScrollBarAccessCallback && this.verticalScrollBarAccessCallback(enabled);
  }

  getVerticalScrollBarAccessEnabled(): boolean {
    return this.verticalScrollBarAccess;
  }

  onVerticalScrollBarAccessChanged(callback: (enabled: boolean) => void): void {
    this.verticalScrollBarAccessCallback = callback;
  }

  setHorizontalScrollBarAccessEnabled(enabled: boolean) {
    this.horizontalScrollBarAccess = enabled;
    this.horizontalScrollBarAccessCallback && this.horizontalScrollBarAccessCallback(enabled);
  }

  getHorizontalScrollBarAccessEnabled(): boolean {
    return this.horizontalScrollBarAccess;
  }

  onHorizontalScrollBarAccessChanged(callback: (enabled: boolean) => void): void {
    this.horizontalScrollBarAccessCallback = callback;
  }
}

class OhosHttpAuthHandler implements HttpAuthHandler {
  private nativeHandler: ESObject;
  private savedUsername: string = '';
  private savedPassword: string = '';

  constructor(handler: ESObject) {
    this.nativeHandler = handler;
  }

  cancel(): void {
    this.nativeHandler.cancel();
  }

  proceed(username: string, password: string): void {
    this.savedUsername = username;
    this.savedPassword = password;
    this.nativeHandler.confirm(username, password);
  }

  useHttpAuthUsernamePassword(): boolean {
    return this.nativeHandler.isHttpAuthInfoSaved?.() ?? false;
  }
}

class OhosSslErrorHandler implements SslErrorHandler {
  private nativeHandler: ESObject;

  constructor(handler: ESObject) {
    this.nativeHandler = handler;
  }

  cancel(): void {
    try {
      if (typeof this.nativeHandler.handleCancel === 'function') {
        try {
          this.nativeHandler.handleCancel(true);
        } catch (_e) {
          this.nativeHandler.handleCancel();
        }
      }
    } catch (err) {
      Log.e(TAG, "OhosSslErrorHandler.cancel err = " + err);
    }
  }

  proceed(): void {
    try {
      this.nativeHandler.handleConfirm?.();
    } catch (err) {
      Log.e(TAG, "OhosSslErrorHandler.proceed err = " + err);
    }
  }
}
