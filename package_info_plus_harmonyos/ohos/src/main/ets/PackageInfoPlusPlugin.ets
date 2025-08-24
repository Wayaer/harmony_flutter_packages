import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';

import bundleManager from '@ohos.bundle.bundleManager'

let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO

export default class PackageInfoPlusPlugin implements FlutterPlugin, MethodCallHandler {
  getUniqueClassName(): string {
    return "PackageInfoPlugin";
  }

  private methodChannel: MethodChannel | null = null;
  private applicationContext: Context | null = null;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = binding.getApplicationContext();
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), "dev.fluttercommunity.plus/package_info");
    this.methodChannel.setMethodCallHandler(this);

  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = null;
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "getAll") {
      const bundleManage = bundleManager.getBundleInfoForSelfSync(bundleFlags);
      const appInfo = bundleManage.appInfo;
      const infoMap = new Map<string, string>();
      const buildSignature = bundleManage.signatureInfo.fingerprint;
      const appName = this.applicationContext?.resourceManager.getStringSync(appInfo.labelId) ?? '';
      infoMap.set("appName", appName);
      infoMap.set("packageName", bundleManage.name);
      infoMap.set("version", bundleManage.versionName);
      infoMap.set("buildNumber", bundleManage.versionCode.toString());
      infoMap.set("buildSignature", buildSignature);
      result.success(infoMap);
    } else {
      result.notImplemented()
    }
  }
}
