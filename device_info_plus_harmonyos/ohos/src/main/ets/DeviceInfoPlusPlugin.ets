import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCall, MethodCallHandler, MethodResult } from '@ohos/flutter_ohos';
import deviceInfo from '@ohos.deviceInfo';

export default class DeviceInfoPlusPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return "DeviceInfoPlusPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'dev.fluttercommunity.plus/device_info');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "getDeviceInfo":
        this.DeviceInfoAssemble().then((data: Map<String, ESObject>) => {
          result.success(data);
        });
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  async DeviceInfoAssemble(): Promise<Map<String, ESObject>> {
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
    data.set('ODID', deviceInfo.ODID);
    return data;
  }
}
