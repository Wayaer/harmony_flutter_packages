// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on HttpAuthHandlerFlutterApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { HttpAuthHandlerFlutterApi, Reply } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager'

export class HttpAuthHandlerFlutterApiImpl {
  binaryMessenger: BinaryMessenger;

  instanceManager: InstanceManager;

  api: HttpAuthHandlerFlutterApi;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
    this.api = new HttpAuthHandlerFlutterApi(binaryMessenger);
  }

  create(instance: ESObject, callback: Reply<void>) {
    if (!this.instanceManager.containsInstance(instance)) {
      this.api.create(this.instanceManager.addHostCreatedInstance(instance), callback);
    }
  }
}
