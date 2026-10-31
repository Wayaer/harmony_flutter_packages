/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
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

import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
} from '@ohos/flutter_ohos';
import { IsEnabledMessage, ToggleMessage, WakelockApi } from './WakelockApi';
import window from '@ohos.window';
import { Context } from '@ohos.abilityAccessCtrl';

export default class WakelockPlusPlugin extends WakelockApi implements FlutterPlugin, AbilityAware {
  private context: Context | null = null;
  private enabled: boolean = false;

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    const context = binding.getAbility().context;
    this.context = context;
    if (this.enabled) {
      window.getLastWindow(context)
        .then((windowClass: window.Window) => windowClass.setWindowKeepScreenOn(true))
        .catch((err: Error) => console.error('restore keepScreenOn failed, err: ' + err));
    }
  }

  onDetachedFromAbility(): void {
    const context = this.context;
    this.context = null;
    // 只有此前确实开启过常亮时才需要复位，避免影响宿主应用自身的设置。
    if (context != null && this.enabled) {
      window.getLastWindow(context)
        .then((windowClass: window.Window) => windowClass.setWindowKeepScreenOn(false))
        .catch((err: Error) => console.error('reset keepScreenOn failed, err: ' + err));
    }
  }

  async toggle(msg: ToggleMessage): Promise<void> {
    const context = this.context;
    if (context == null) {
      throw new Error('WakelockPlusPlugin context is not ready');
    }
    try {
      let windowClass = await window.getLastWindow(context);
      await windowClass.setWindowKeepScreenOn(msg.getEnable());
      this.enabled = msg.getEnable();
    }
    catch (err) {
      console.error('toggle failed, err: ' + err);
      throw new Error('toggle keepScreenOn failed: ' + JSON.stringify(err));
    }
  }

  async isEnabled(): Promise<IsEnabledMessage> {
    let isEnabled = false;
    try {
      if (this.context != null) {
        let windowClass = await window.getLastWindow(this.context);
        isEnabled = windowClass.getWindowProperties().isKeepScreenOn;
      }
    }
    catch (err) {
      console.error('toggle failed, err: ' + err);
    }

    return new IsEnabledMessage(isEnabled);
  }

  getUniqueClassName(): string {
    return "WakelockPlusPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    WakelockApi.setup(binding.getBinaryMessenger(), this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    WakelockApi.setup(binding.getBinaryMessenger(), null);
  }
}