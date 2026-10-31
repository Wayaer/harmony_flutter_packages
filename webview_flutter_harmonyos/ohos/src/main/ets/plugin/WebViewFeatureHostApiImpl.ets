// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import { WebViewFeatureHostApi } from './GeneratedOhosWebView';

export class WebViewFeatureHostApiImpl extends WebViewFeatureHostApi {
  isFeatureSupported(feature: string): boolean {
    switch (feature) {
      case 'PAYMENT_REQUEST':
        return false;
      default:
        return false;
    }
  }
}