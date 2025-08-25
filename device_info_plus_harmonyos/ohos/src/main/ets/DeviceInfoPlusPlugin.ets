import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCall, MethodCallHandler, MethodResult } from '@ohos/flutter_ohos';
import deviceInfo from '@ohos.deviceInfo';
import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';

export default class DeviceInfoPlusPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;
  private harmonyChannel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return "DeviceInfoPlusPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'dev.fluttercommunity.plus/device_info');
    this.channel.setMethodCallHandler(this);
    this.harmonyChannel =
      new MethodChannel(binding.getBinaryMessenger(), 'dev.fluttercommunity.plus/device_info_harmony');
    this.harmonyChannel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.harmonyChannel?.setMethodCallHandler(null);
    this.harmonyChannel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "getDeviceInfo":
        result.success(this.deviceInfo())
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  deviceInfo(): Map<String, ESObject> {
    let data: Map<String, ESObject> = new Map();
    data.set('deviceType', deviceInfo.deviceType);
    data.set('manufacture', deviceInfo.manufacture);
    data.set('brand', deviceInfo.brand);
    data.set('marketName', deviceInfo.marketName);
    data.set('productSeries', deviceInfo.productSeries);
    data.set('productModel', deviceInfo.productModel);
    data.set('softwareModel', deviceInfo.softwareModel);
    data.set('hardwareModel', deviceInfo.hardwareModel);
    data.set('hardwareProfile', deviceInfo.hardwareProfile);
    data.set('bootloaderVersion', deviceInfo.bootloaderVersion);
    data.set('abiList', deviceInfo.abiList);
    data.set('securityPatchTag', deviceInfo.securityPatchTag);
    data.set('displayVersion', deviceInfo.displayVersion);
    data.set('incrementalVersion', deviceInfo.incrementalVersion);
    data.set('osReleaseType', deviceInfo.osReleaseType);
    data.set('osFullName', deviceInfo.osFullName);
    data.set('majorVersion', deviceInfo.majorVersion);
    data.set('seniorVersion', deviceInfo.seniorVersion);
    data.set('featureVersion', deviceInfo.featureVersion);
    data.set('buildVersion', deviceInfo.buildVersion);
    data.set('sdkApiVersion', deviceInfo.sdkApiVersion);
    data.set('firstApiVersion', deviceInfo.firstApiVersion);
    data.set('versionId', deviceInfo.versionId);
    data.set('buildType', deviceInfo.buildType);
    data.set('buildUser', deviceInfo.buildUser);
    data.set('buildHost', deviceInfo.buildHost);
    data.set('buildTime', deviceInfo.buildTime);
    data.set('buildRootHash', deviceInfo.buildRootHash);
    data.set('distributionOSName', deviceInfo.distributionOSName);
    data.set('distributionOSVersion', deviceInfo.distributionOSVersion);
    data.set('distributionOSApiVersion', deviceInfo.distributionOSApiVersion);
    data.set('distributionOSReleaseType', deviceInfo.distributionOSReleaseType);
    data.set('odId', deviceInfo.ODID);
    data.set('isPhysicalDevice', !this.isEmulator());
    if (this.checkPermission('ohos.permission.sec.ACCESS_UDID')) {
      data.set('serial', deviceInfo.serial);
      data.set('udid', deviceInfo.udid);
    }
    return data;
  }

  isEmulator(): Boolean {
    return deviceInfo.versionId.includes('emulator') || deviceInfo.displayVersion.includes('emulator');
  }


  checkPermission(permissions: Permissions): boolean {
    try {
      const result =
        abilityAccessCtrl.createAtManager()
          .checkAccessTokenSync(this.context?.applicationInfo.accessTokenId, 'ohos.permission.sec.ACCESS_UDID');
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    } catch (error) {
      console.log(`checkPermission(${permissions}) error: ${error}`)
      return false
    }
  }
}
