/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter/services.dart';

/// 应用内 WebView 的配置项。
class WebViewOptions {
  WebViewOptions({required this.enableJavaScript, required this.enableDomStorage, required this.headers});

  bool enableJavaScript;

  bool enableDomStorage;

  Map<String?, String?> headers;

  Object encode() {
    return <Object?>[enableJavaScript, enableDomStorage, headers];
  }

  static WebViewOptions decode(Object result) {
    result as List<Object?>;
    return WebViewOptions(
      enableJavaScript: result[0]! as bool,
      enableDomStorage: result[1]! as bool,
      headers: (result[2] as Map<Object?, Object?>?)!.cast<String?, String?>(),
    );
  }
}

/// 浏览器视图的配置项。
class BrowserOptions {
  BrowserOptions({required this.showTitle});

  bool showTitle;

  Object encode() {
    return <Object?>[showTitle];
  }

  static BrowserOptions decode(Object result) {
    result as List<Object?>;
    return BrowserOptions(showTitle: result[0]! as bool);
  }
}

class _UrlLauncherApiCodec extends StandardMessageCodec {
  const _UrlLauncherApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is WebViewOptions) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is BrowserOptions) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return WebViewOptions.decode(readValue(buffer)!);
      case 129:
        return BrowserOptions.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class UrlLauncherApi {
  /// [UrlLauncherApi] 构造函数。[binaryMessenger] 命名参数用于依赖注入，
  /// 为 null 时使用默认 BinaryMessenger，路由到宿主平台。
  UrlLauncherApi({BinaryMessenger? binaryMessenger}) : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _UrlLauncherApiCodec();

  /// 判断 URL 是否可以确定被打开。
  Future<bool> canLaunchUrl(String argUrl) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.UrlLauncherApi.canLaunchUrl',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final List<Object?>? replyList = await channel.send(<Object?>[argUrl]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  /// 在外部打开 URL，成功时返回 true。
  Future<bool> launchUrl(String argUrl, Map<String?, String?> argHeaders) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.UrlLauncherApi.launchUrl',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final List<Object?>? replyList = await channel.send(<Object?>[argUrl, argHeaders]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  /// 在应用内 WebView 中打开 URL，打开成功时返回 true。
  Future<bool> openUrlInWebView(String argUrl, WebViewOptions argOptions, BrowserOptions argBrowserOptions) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.UrlLauncherApi.openUrlInWebView',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final List<Object?>? replyList =
        await channel.send(<Object?>[argUrl, argOptions, argBrowserOptions]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  /// 关闭由 [openUrlInSafariViewController] 打开的视图。
  Future<void> closeWebView() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.UrlLauncherApi.closeWebView',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final List<Object?>? replyList = await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else {
      return;
    }
  }
}
