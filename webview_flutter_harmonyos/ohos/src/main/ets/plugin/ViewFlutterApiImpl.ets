// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on ViewFlutterApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { ViewFlutterApi, Reply } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager'

export class ViewFlutterApiImpl {
  binaryMessenger: BinaryMessenger;

  instanceManager: InstanceManager;
  api: ViewFlutterApi;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
    this.api = new ViewFlutterApi(binaryMessenger);
  }

  create(instance: ESObject, callback: Reply<void>) {
    if (!this.instanceManager.containsInstance(instance)) {
      this.api.create(this.instanceManager.addHostCreatedInstance(instance), callback);
    }
  }

  setApi(api: ViewFlutterApi) {
    this.api = api;
  }
}
