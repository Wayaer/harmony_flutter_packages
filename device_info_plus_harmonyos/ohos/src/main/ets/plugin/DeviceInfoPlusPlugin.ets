/**
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import deviceInfo from '@ohos.deviceInfo';
import HashMap from '@ohos.util.HashMap';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

export default class DeviceInfoPlusPlugin implements FlutterPlugin, MethodCallHandler {
  private readonly CHANNEL_NAME: string = 'dev.fluttercommunity.plus/device_info';

  private readonly METHOD_GET_DEVICE_INFO: string = 'getDeviceInfo';

  private readonly METHOD_GET_ACCESS_UDID: string = 'getAccessUDIDInfo';

  /** 版本标识中出现该标记即视为模拟器运行时。 */
  private readonly EMULATOR_TAG: string = 'emulator';

  private channel: MethodChannel | null = null;

  private context: common.Context | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'DeviceInfoPlusPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), this.CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }

  /** 异常（如缺少 UDID 权限）通过 result.error 回传给 Flutter，避免未捕获异常导致宿主崩溃。 */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      if (call.method === this.METHOD_GET_DEVICE_INFO) {
        result.success(this.buildDeviceInfoMap());
      } else if (call.method === this.METHOD_GET_ACCESS_UDID) {
        result.success(this.buildAccessUDIDMap());
      } else {
        result.notImplemented();
      }
    } catch (e) {
      // 权限被拒等情况回传给 Flutter，避免插件崩溃宿主；每条路径只调用一次 result。
      const reason = e instanceof Error ? (e.message ?? '') : String(e);
      result.error('DEVICE_INFO_ERROR', `${call.method} failed: ${reason}`, null);
    }
  }

  private buildDeviceInfoMap(): HashMap<string, Object> {
    const infoMap: HashMap<string, Object> = new HashMap<string, Object>();
    infoMap.set('deviceType', deviceInfo.deviceType);
    infoMap.set('manufacture', deviceInfo.manufacture);
    infoMap.set('brand', deviceInfo.brand);
    infoMap.set('marketName', deviceInfo.marketName);
    infoMap.set('productSeries', deviceInfo.productSeries);
    infoMap.set('productModel', deviceInfo.productModel);
    infoMap.set('softwareModel', deviceInfo.softwareModel);
    infoMap.set('hardwareModel', deviceInfo.hardwareModel);
    infoMap.set('hardwareProfile', deviceInfo.hardwareProfile);
    infoMap.set('bootloaderVersion', deviceInfo.bootloaderVersion);
    infoMap.set('abiList', deviceInfo.abiList);
    infoMap.set('securityPatchTag', deviceInfo.securityPatchTag);
    infoMap.set('displayVersion', deviceInfo.displayVersion);
    infoMap.set('incrementalVersion', deviceInfo.incrementalVersion);
    infoMap.set('osReleaseType', deviceInfo.osReleaseType);
    infoMap.set('osFullName', deviceInfo.osFullName);
    infoMap.set('majorVersion', deviceInfo.majorVersion);
    infoMap.set('seniorVersion', deviceInfo.seniorVersion);
    infoMap.set('featureVersion', deviceInfo.featureVersion);
    infoMap.set('buildVersion', deviceInfo.buildVersion);
    infoMap.set('sdkApiVersion', deviceInfo.sdkApiVersion);
    infoMap.set('firstApiVersion', deviceInfo.firstApiVersion);
    infoMap.set('versionId', deviceInfo.versionId);
    infoMap.set('buildType', deviceInfo.buildType);
    infoMap.set('buildUser', deviceInfo.buildUser);
    infoMap.set('buildHost', deviceInfo.buildHost);
    infoMap.set('buildTime', deviceInfo.buildTime);
    infoMap.set('buildRootHash', deviceInfo.buildRootHash);
    infoMap.set('odId', deviceInfo.ODID); // ohos.permission.APP_TRACKING_CONSENT 用户授权才能获取有效值
    infoMap.set('distributionOSName', deviceInfo.distributionOSName);
    infoMap.set('distributionOSVersion', deviceInfo.distributionOSVersion);
    infoMap.set('distributionOSApiVersion', deviceInfo.distributionOSApiVersion);
    infoMap.set('distributionOSReleaseType', deviceInfo.distributionOSReleaseType);
    infoMap.set('isPhysicalDevice', !this.isEmulator());
    if (this.checkPermission('ohos.permission.sec.ACCESS_UDID')) {
      // 缺少权限或读取异常时跳过这两个字段，避免整个设备信息查询失败。
      try {
        infoMap.set('serial', deviceInfo.serial);
        infoMap.set('udid', deviceInfo.udid);
      } catch (e) {
        const reason = e instanceof Error ? (e.message ?? '') : String(e);
        console.log(`read serial/udid failed: ${reason}`);
      }
    }
    return infoMap;
  }

  /** 需要系统权限 ohos.permission.sec.ACCESS_UDID，缺失时读取会抛错并交由 onMethodCall 回传。 */
  private buildAccessUDIDMap(): HashMap<string, Object> {
    const infoMap: HashMap<string, Object> = new HashMap<string, Object>();
    infoMap.set('serial', deviceInfo.serial);
    infoMap.set('udid', deviceInfo.udid);
    return infoMap;
  }

  private isEmulator(): boolean {
    return deviceInfo.versionId.includes(this.EMULATOR_TAG) ||
      deviceInfo.displayVersion.includes(this.EMULATOR_TAG);
  }

  private checkPermission(permission: Permissions): boolean {
    try {
      const result = abilityAccessCtrl.createAtManager()
        .checkAccessTokenSync(this.context?.applicationInfo.accessTokenId, permission);
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      console.log(`checkPermission(${permission}) error: ${error}`);
      return false;
    }
  }
}
