// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import web_webview from '@ohos.web.webview'
import PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { WebViewPlatformView } from './WebViewHostApiImpl';
import { Any } from '@ohos/flutter_ohos';
import { commonEventManager } from '@kit.BasicServicesKit';
@Observed
export declare class Params {
  direction: Direction
  platformView: PlatformView
}

@Component
export struct OhosWebView {
  @ObjectLink params: Params;
  webView: WebViewPlatformView = this.params.platformView as WebViewPlatformView;
  controller: web_webview.WebviewController = this.webView.getController();
  lastExecTime = 0;

  @State textZoomRatio: number = this.webView.getWebSettings().getTextZoom();
  @State supportMultipleWindows: boolean = this.webView.getWebSettings().getSupportMultipleWindows();
  @State verticalScrollBarAccess: boolean = this.webView.getWebSettings().getVerticalScrollBarAccessEnabled();
  @State horizontalScrollBarAccess: boolean = this.webView.getWebSettings().getHorizontalScrollBarAccessEnabled();
  @State disposed: boolean = false;
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  aboutToAppear() {
    this.webView.getWebSettings().onTextZoomChanged((ratio: number) => {
      this.textZoomRatio = ratio;
    });
    this.webView.getWebSettings().onVerticalScrollBarAccessChanged((enabled: boolean) => {
      this.verticalScrollBarAccess = enabled;
    });
    this.webView.getWebSettings().onSupportMultipleWindowsChanged((support: boolean) => {
      this.supportMultipleWindows = support;
    });
    this.webView.getWebSettings().onHorizontalScrollBarAccessChanged((enabled: boolean) => {
      this.horizontalScrollBarAccess = enabled;
    });
    this.webView.setOnDisposeCallback(() => {
      this.disposed = true;
    });

    commonEventManager.createSubscriber(
      { events: ["usual.event.CLICK_STATUSBAR"] }, (err, subscriber) => {
      this.subscriber = subscriber
      if(subscriber !== null) {
        commonEventManager.subscribe(subscriber, (err, data) => {
          this.throttle(() => {
            this.webView.waitControllerAttached().then(() => {
              this.controller?.scrollTo(0, 0, 1000);
            });
          }, 1000)
        })
      }
    });
  }

  throttle(func: Function, delay: number) {
    const currentTime = Date.now();
    if (currentTime - this.lastExecTime >= delay) {
      func();
      this.lastExecTime = currentTime;
    }
  }

  aboutToDisappear() {
    if (this.subscriber != null) {
      commonEventManager.unsubscribe(this.subscriber);
      this.subscriber = null;
    }
  }

  getMixedModeValue(): MixedMode {
    const mode: number = this.webView.getWebSettings().getMixedMode();
    switch (mode) {
      case 0:
        return MixedMode.All;
      case 1:
        return MixedMode.Compatible;
      case 2:
        return MixedMode.None;
      default:
        return MixedMode.All;
    }
  }

  getOverScrollModeValue(): OverScrollMode {
    const mode: number = this.webView.getWebSettings().getOverScrollMode();
    switch (mode) {
      case 0:
        return OverScrollMode.NEVER;
      case 1:
        return OverScrollMode.ALWAYS;
      default:
        return OverScrollMode.NEVER;
    }
  }

  build() {
    Column() {
      if (!this.disposed) {
        Web(
          {
            src: this.webView.getUrl(),
            controller: this.controller
          })
          .keyboardAvoidMode(WebKeyboardAvoidMode.RESIZE_VISUAL)
          .backgroundColor(this.webView.getWebSettings().getBackgroundColor())
          .onDownloadStart(this.webView.onDownloadStart)
          .onPageBegin(this.webView.onPageBegin)
          .onPageEnd(this.webView.onPageEnd)
          .onErrorReceive(this.webView.onErrorReceive)
          .onHttpErrorReceive(this.webView.onHttpErrorReceive)
          .onRefreshAccessedHistory(this.webView.onRefreshAccessedHistory)
          .onProgressChange(this.webView.onProgressChange)
          .onGeolocationShow(this.webView.onGeolocationShow)
          .onGeolocationHide(this.webView.onGeolocationHide)
          .onShowFileSelector(this.webView.onShowFileSelector)
          .onPermissionRequest(this.webView.onPermissionRequest)
          .onConsole(this.webView.onConsoleMessage)
          .onWindowExit(this.webView.onWindowExit)
          .domStorageAccess(this.webView.getWebSettings().getDomStorageEnabled())
          .allowWindowOpenMethod(this.webView.getWebSettings().getJavaScriptCanOpenWindowsAutomatically())
          .multiWindowAccess(this.supportMultipleWindows)
          .javaScriptAccess(this.webView.getWebSettings().getJavaScriptEnabled())
          .mediaPlayGestureAccess(this.webView.getWebSettings().getMediaPlaybackRequiresUserGesture())
          .zoomAccess(this.webView.getWebSettings().getSupportZoom())
          .overviewModeAccess(this.webView.getWebSettings().getLoadWithOverviewMode())
          .wideViewModeAccess(this.webView.getWebSettings().getUseWideViewPort())
          .fileAccess(this.webView.getWebSettings().getAllowFileAccess())
          .textZoomRatio(this.textZoomRatio)
          .verticalScrollBarAccess(this.verticalScrollBarAccess)
          .horizontalScrollBarAccess(this.horizontalScrollBarAccess)
          .onScroll(this.webView.onScroll)
          .onControllerAttached(this.webView.onControllerAttached)
          .onWindowNew((event: Any) => {
            let newWebViewController: web_webview.WebviewController = new web_webview.WebviewController();
            let dialogController: CustomDialogController = new CustomDialogController({
              builder: NewWebView({ webViewController: newWebViewController })
            })
            dialogController.open();
            event.handler.setWebController(newWebViewController);
          })
          .onSslErrorEventReceive(this.webView.onSslErrorReceive)
          .onHttpAuthRequest(this.webView.onHttpAuthRequest)
          .onAlert(this.webView.onJsAlert)
          .onConfirm(this.webView.onJsConfirm)
          .onPrompt(this.webView.onJsPrompt)
          .mixedMode(this.getMixedModeValue())
          .overScrollMode(this.getOverScrollModeValue())
          .onOverrideUrlLoading(this.webView.onOverrideUrlLoading)
          .onFullScreenEnter(this.webView.onFullScreenEnter)
          .onFullScreenExit(this.webView.onFullScreenExit)
      }
    }
  }
}

@Builder
export function WebBuilder(params: Params) {
  OhosWebView({
    params: params,
    webView: params.platformView as WebViewPlatformView,
    controller: (params.platformView as WebViewPlatformView).getController()
  }).backgroundColor(Color.Transparent)
}

@CustomDialog
struct NewWebView {
  controller?: CustomDialogController
  webViewController: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Web({ src: "", controller: this.webViewController })
      .javaScriptAccess(true)
      .multiWindowAccess(false)
      .onWindowExit(
        () => {
          if (this.controller) {
            this.controller.close();
          }
        }
      )
  }
}