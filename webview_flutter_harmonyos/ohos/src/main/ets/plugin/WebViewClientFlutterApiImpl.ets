// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on WebViewClientFlutterApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import {
  Reply,
  WebResourceErrorData,
  WebResourceRequestData,
  WebViewClientFlutterApi,
  WebViewFlutterApi,
  HttpAuthHandler,
  SslErrorHandler,
} from './GeneratedOhosWebView';
import { HttpAuthHandlerFlutterApiImpl } from './HttpAuthHandlerFlutterApiImpl';
import { SslErrorHandlerFlutterApiImpl } from './SslErrorHandlerFlutterApiImpl';
import { InstanceManager } from './InstanceManager';
import { WebViewClient } from './WebViewClientHostApiImpl';
import { WebViewFlutterApiImpl } from './WebViewFlutterApiImpl';
import { WebViewHostApiImpl, WebViewPlatformView } from './WebViewHostApiImpl';

export class WebViewClientFlutterApiImpl extends WebViewClientFlutterApi {
  private instanceManager: InstanceManager;
  private webViewFlutterApi: WebViewFlutterApiImpl;
  private emptyReply: Reply<void> = {
    reply: (reply) => {
    }
  }

  static createWebResourceErrorData(resource: WebResourceError | WebResourceResponse): WebResourceErrorData {
    if (!resource) {
      return WebResourceErrorData.Builder().setErrorCode(-1).setDescription('Unknown error').build();
    }
    if(resource instanceof WebResourceResponse){
      return WebResourceErrorData.Builder()
      .setErrorCode(resource.getResponseCode())
      .setDescription(resource.getReasonMessage())
      .build();
    }
    return WebResourceErrorData.Builder()
      .setErrorCode(resource.getErrorCode())
      .setDescription(resource.getErrorInfo())
      .build();
  }

  static toWebHeadersMap(headers: Array<Header>) {
    let headersMap: Map<string, string> = new Map();
    if (headers == null || headers.length == 0) {
      return headersMap;
    }
    for (let header of headers) {
      headersMap.set(header.headerKey, header.headerValue);
    }
    return headersMap;
  }

  static createWebResourceRequestData(request: WebResourceRequest): WebResourceRequestData {
    return WebResourceRequestData.Builder()
      .setUrl(request.getRequestUrl())
      .setIsForMainFrame(request.isMainFrame())
      .setIsRedirect(request.isRedirect())
      .setHasGesture(request.isRequestGesture())
      .setMethod(request.getRequestMethod())
      .setRequestHeaders(WebViewClientFlutterApiImpl.toWebHeadersMap(request.getRequestHeader()))
      .build();
  }

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    super(binaryMessenger);
    this.instanceManager = instanceManager;
    this.webViewFlutterApi = new WebViewFlutterApiImpl(binaryMessenger, instanceManager);
  }

  onPageStartedImpl(
    webViewClient: WebViewClient,
    webView: WebViewPlatformView,
    urlArg: string,
    callback: Reply<void>
  ) {
    this.webViewFlutterApi.create(webView, this.emptyReply);
    const webViewIdentifier: number = this.instanceManager.getIdentifier(webView);
    this.onPageStarted(this.getIdentifierForClient(webViewClient), webViewIdentifier, urlArg, callback);
  }

  onPageFinishedImpl(
    webViewClient: WebViewClient,
    webView: WebViewPlatformView,
    urlArg: string,
    callback: Reply<void>
  ) {
    this.webViewFlutterApi.create(webView, this.emptyReply);
    const webViewIdentifier: number = this.instanceManager.getIdentifier(webView);
    this.onPageFinished(this.getIdentifierForClient(webViewClient), webViewIdentifier, urlArg, callback);
  }

  onReceivedRequestErrorImpl(
    webViewClient: WebViewClient,
    webView: WebViewPlatformView,
    request: WebResourceRequest,
    error: WebResourceError,
    callback: Reply<void>
  ) {
    this.webViewFlutterApi.create(webView, this.emptyReply);
    const webViewIdentifier: number = this.instanceManager.getIdentifier(webView);

    this.onReceivedRequestError(
      this.getIdentifierForClient(webViewClient),
      webViewIdentifier,
      WebViewClientFlutterApiImpl.createWebResourceRequestData(request),
      WebViewClientFlutterApiImpl.createWebResourceErrorData(error),
      callback
    )
  }

  onReceivedHttpErrorImpl(
    webViewClient: WebViewClient,
    webView: WebViewPlatformView,
    request: WebResourceRequest,
    response: WebResourceResponse,
    callback: Reply<void>
  ) {
    this.webViewFlutterApi.create(webView, this.emptyReply);
    const webViewIdentifier: number = this.instanceManager.getIdentifier(webView);

    this.onReceivedHttpError(
      this.getIdentifierForClient(webViewClient),
      webViewIdentifier,
      WebViewClientFlutterApiImpl.createWebResourceRequestData(request),
      WebViewClientFlutterApiImpl.createWebResourceErrorData(response),
      callback
    )
  }

  requestLoadingImpl(
    webViewClient: WebViewClient,
    webView: WebViewPlatformView,
    request: WebResourceRequest,
    callback: Reply<void>
  ) {
    this.webViewFlutterApi.create(webView, this.emptyReply);
    const webViewIdentifier: number = this.instanceManager.getIdentifier(webView);

    this.requestLoading(
      this.getIdentifierForClient(webViewClient),
      webViewIdentifier,
      WebViewClientFlutterApiImpl.createWebResourceRequestData(request),
      callback
    )
  }

  doUpdateVisitedHistoryImpl(
    webViewClient: WebViewClient,
    webView: WebViewPlatformView,
    url: string,
    isReload: boolean,
    callback: Reply<void>
  ) {
    this.webViewFlutterApi.create(webView, this.emptyReply);
    const webViewIdentifier: number = this.instanceManager.getIdentifier(webView);

    this.doUpdateVisitedHistory(
      this.getIdentifierForClient(webViewClient),
      webViewIdentifier,
      url,
      isReload,
      callback
    )
  }

  onReceivedHttpAuthRequestImpl(
    webViewClient: WebViewClient,
    webview: WebViewPlatformView,
    httpAuthHandler: HttpAuthHandler,
    host: string,
    realm: string,
    callback: Reply<void>
  ) {
    new HttpAuthHandlerFlutterApiImpl(this.binaryMessenger, this.instanceManager)
        .create(httpAuthHandler, this.emptyReply);

    this.onReceivedHttpAuthRequest(
        this.instanceManager.getIdentifier(webViewClient),
        this.instanceManager.getIdentifier(webview),
        this.instanceManager.getIdentifier(httpAuthHandler),
        host,
        realm,
        callback);
  }

  onReceivedSslErrorImpl(
    webViewClient: WebViewClient,
    webView: WebViewPlatformView,
    sslHandler: SslErrorHandler,
    urlArg: string,
    certificateArg: string,
    descriptionArg: string,
    callback: Reply<void>,
  ) {
    const sslFlutterApi =
      new SslErrorHandlerFlutterApiImpl(this.binaryMessenger, this.instanceManager);
    sslFlutterApi.create(sslHandler as ESObject, {
      reply: () => {
        this.onReceivedSslError(
          this.instanceManager.getIdentifier(webViewClient),
          this.instanceManager.getIdentifier(webView),
          this.instanceManager.getIdentifier(sslHandler as ESObject),
          urlArg,
          certificateArg,
          descriptionArg,
          callback,
        );
      },
    });
  }

  getIdentifierForClient(webViewClient: WebViewClient): number {
    let identifier: number = this.instanceManager.getIdentifier(webViewClient);
    if (identifier == null) {
      throw new Error("Could not find identifier for WebViewClient.");
    }
    return identifier;
  }
}