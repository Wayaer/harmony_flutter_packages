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

import connection from '@ohos.net.connection'
import { ArrayList } from '@kit.ArkTS';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG = "Connectivity";

export class Connectivity {
  public static CONNECTIVITY_NONE = "none";
  private static CONNECTIVITY_WIFI = "wifi";
  private static CONNECTIVITY_MOBILE = "mobile";
  private static CONNECTIVITY_ETHERNET = "ethernet";
  private static CONNECTIVITY_BLUETOOTH = "bluetooth";
  private static CONNECTIVITY_VPN = "vpn";
  private static CONNECTIVITY_OTHER = "other";
  public static netConnection = connection.createNetConnection();

  constructor() {
  }

  async getNetworkType(): Promise<ArrayList<String>> {
    const types: ArrayList<String> = new ArrayList();
    try {
      if (!await connection.hasDefaultNet()) {
        types.add(Connectivity.CONNECTIVITY_NONE);
        return types;
      }
      const netHandle = await connection.getDefaultNet();
      if (netHandle.netId == 0) {
        types.add(Connectivity.CONNECTIVITY_NONE);
        return types;
      }
      const capabilities = await connection.getNetCapabilities(netHandle);
      return this.hasTransport(capabilities.bearerTypes);
    } catch (err) {
      Log.e(TAG, "Failed to get network type: " + JSON.stringify(err));
      types.add(Connectivity.CONNECTIVITY_NONE);
      return types;
    }
  }

  hasTransport(capabilities: Array<connection.NetBearType>): ArrayList<String> {
    const types: ArrayList<String> = new ArrayList();
    if (capabilities.length == 0) {
      types.add(Connectivity.CONNECTIVITY_NONE);
      return types;
    }
    if (capabilities.includes(connection.NetBearType.BEARER_WIFI)) {
      types.add(Connectivity.CONNECTIVITY_WIFI);
    }
    if (capabilities.includes(connection.NetBearType.BEARER_ETHERNET)) {
      types.add(Connectivity.CONNECTIVITY_ETHERNET);
    }
    if (capabilities.includes(connection.NetBearType.BEARER_CELLULAR)) {
      types.add(Connectivity.CONNECTIVITY_MOBILE);
    }
    if (capabilities.includes(connection.NetBearType.BEARER_BLUETOOTH)) {
      types.add(Connectivity.CONNECTIVITY_BLUETOOTH);
    }
    if (capabilities.includes(connection.NetBearType.BEARER_VPN)) {
      types.add(Connectivity.CONNECTIVITY_VPN);
    }
    if (types.length == 0) {
      // 存在承载类型但未命中已知枚举时，安全兜底为 other（如后续新增的承载类型）。
      types.add(Connectivity.CONNECTIVITY_OTHER);
    }
    return types;
  }
}
