/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
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

import { StreamHandler, EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { Connectivity } from './Connectivity';
import connection from '@ohos.net.connection';
import { AsyncCallback, BusinessError } from '@ohos.base';
import { ArrayList } from '@kit.ArkTS';

const TAG = "ConnectivityBroadcastReceiver";

export class ConnectivityBroadcastReceiver implements StreamHandler {
  private connectivity: Connectivity;
  private events: EventSink | null = null;
  private netConnection: connection.NetConnection | null = null;
  private registerCallback: AsyncCallback<void> | null = null;
  /** 订阅代次：取消订阅后递增，用于丢弃旧订阅仍在途的异步查询结果。 */
  private listenGeneration: number = 0;

  constructor(connectivity: Connectivity) {
    this.connectivity = connectivity;
  }

  onListen(args: Object, events: EventSink): void {
    // 先清理上一次的监听，避免重复订阅。
    this.stopListening();
    this.events = events;
    const generation: number = ++this.listenGeneration;
    // 与 Android 保持一致：订阅时立即发送一次当前网络状态。
    this.sendCurrentNetworkType(generation);

    // 每次订阅使用独立的 NetConnection，保证取消后旧监听可以被彻底释放。
    const netConnection = connection.createNetConnection();
    this.netConnection = netConnection;

    const registerCallback: AsyncCallback<void> = (error: BusinessError): void => {
      if (error != null) {
        console.error(TAG + ' register failed: ' + JSON.stringify(error));
        return;
      }
      // 注册成功后再订阅事件，避免注册失败时事件监听无效。
      if (this.netConnection !== netConnection || generation !== this.listenGeneration) {
        return;
      }
      this.subscribeNetworkEvents(netConnection, generation);
    };
    this.registerCallback = registerCallback;
    netConnection.register(registerCallback);
  }

  private subscribeNetworkEvents(netConnection: connection.NetConnection, generation: number): void {
    netConnection.on('netAvailable', (data: connection.NetHandle): void => {
      this.sendCurrentNetworkType(generation);
    });

    netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo): void => {
      this.sendCurrentNetworkType(generation);
    });

    netConnection.on('netConnectionPropertiesChange', (data: connection.NetConnectionPropertyInfo): void => {
      this.sendCurrentNetworkType(generation);
    });

    // 网络丢失时重新查询，避免 Wi-Fi 断开但有蜂窝时误报 none。
    netConnection.on('netLost', (data: connection.NetHandle): void => {
      this.sendCurrentNetworkType(generation);
    });

    netConnection.on('netUnavailable', (): void => {
      this.sendCurrentNetworkType(generation);
    });
  }

  onCancel(args?: Object): void {
    this.stopListening();
  }

  private stopListening(): void {
    // 递增代次，使旧订阅仍在途的异步查询结果不再发送给新的订阅者。
    this.listenGeneration++;
    if (this.netConnection !== null) {
      try {
        if (this.registerCallback !== null) {
          this.netConnection.unregister(this.registerCallback);
        }
      } catch (err) {
        console.log(TAG + ' unregister failed: ' + JSON.stringify(err));
      }
      this.netConnection = null;
    }
    this.registerCallback = null;
    this.events = null;
  }

  private async sendCurrentNetworkType(generation: number): Promise<void> {
    try {
      this.sendEvent(generation, await this.connectivity.getNetworkType());
    } catch (err) {
      // 查询失败时不上报事件，同时避免产生未捕获的 Promise 拒绝。
      console.error(TAG + ' getNetworkType failed: ' + JSON.stringify(err));
    }
  }

  private sendEvent(generation: number, networkType: ArrayList<String>): void {
    if (generation === this.listenGeneration && this.events != null && networkType != null) {
      this.events.success(networkType);
    }
  }
}
