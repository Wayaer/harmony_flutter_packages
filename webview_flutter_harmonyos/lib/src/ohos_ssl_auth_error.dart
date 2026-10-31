// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:webview_flutter_harmonyos/src/ohos_webview.dart' as ohos;

class OhosSslAuthError extends PlatformSslAuthError {
  OhosSslAuthError._({
    required super.certificate,
    required super.description,
    required this.url,
    required ohos.SslErrorHandler handler,
  }) : _handler = handler;

  final ohos.SslErrorHandler _handler;

  final String url;

  @internal
  static Future<OhosSslAuthError> fromNativeCallback({
    required ohos.SslErrorHandler handler,
    required String url,
    required String certificateHint,
    required String description,
  }) async {
    final String fullDescription = certificateHint.trim().isEmpty
        ? description
        : '$description\nIssuer hint: $certificateHint';
    return OhosSslAuthError._(certificate: null, description: fullDescription, url: url, handler: handler);
  }

  @override
  Future<void> cancel() => _handler.cancel();

  @override
  Future<void> proceed() => _handler.proceed();
}
