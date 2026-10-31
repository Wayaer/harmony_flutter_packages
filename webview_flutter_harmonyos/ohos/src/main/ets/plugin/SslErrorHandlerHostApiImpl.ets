/*
 * Copyright (c) 2026 Huawei Device Co., Ltd. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE_HW file.
 */

import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { SslErrorHandlerHostApi, SslErrorHandler } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager';

export class SslErrorHandlerHostApiImpl extends SslErrorHandlerHostApi {
  binaryMessenger: BinaryMessenger;

  instanceManager: InstanceManager;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    super();
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
  }

  cancel(instanceId: number): void {
    this.getSslErrorHandler(instanceId).cancel();
  }

  proceed(instanceId: number): void {
    this.getSslErrorHandler(instanceId).proceed();
  }

  private getSslErrorHandler(instanceId: number): SslErrorHandler {
    return this.instanceManager.getInstance(instanceId);
  }
}
