import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import EventChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { ConnectivityBroadcastReceiver } from './ConnectivityBroadcastReceiver';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { Log, MethodCall, MethodCallHandler, MethodResult } from '@ohos/flutter_ohos';
import { ArrayList } from '@kit.ArkTS';
import connection from '@ohos.net.connection';

export default class ConnectivityPlusPlugin implements FlutterPlugin, MethodCallHandler {
  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private receiver: ConnectivityBroadcastReceiver | null = null;

  getUniqueClassName(): string {
    return "ConnectivityPlusPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), "dev.fluttercommunity.plus/connectivity",
      StandardMethodCodec.INSTANCE);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), "dev.fluttercommunity.plus/connectivity_status",
      StandardMethodCodec.INSTANCE);
    this.receiver = new ConnectivityBroadcastReceiver();
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel.setStreamHandler(this.receiver);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
    this.receiver?.onCancel();
    this.methodChannel = null;
    this.eventChannel = null;
    this.receiver = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case "check":
        ConnectivityPlusPlugin.getNetworkType().then((value) => {
          result.success(value)
        })
        break;
      default:
        result.notImplemented();
        break;
    }
  }


  public static CONNECTIVITY_NONE = "none";
  private static CONNECTIVITY_WIFI = "wifi";
  private static CONNECTIVITY_MOBILE = "mobile";
  private static CONNECTIVITY_ETHERNET = "ethernet";
  private static CONNECTIVITY_BLUETOOTH = "bluetooth";
  private static CONNECTIVITY_VPN = "vpn";
  public static netConnection = connection.createNetConnection();

  static async getNetworkType(): Promise<ArrayList<String>> {
    const types: ArrayList<String> = new ArrayList();
    try {
      const hasDefaultNet = connection.hasDefaultNet()
      if (!hasDefaultNet) {
        types.add(ConnectivityPlusPlugin.CONNECTIVITY_NONE);
        return types;
      }
      const netHandle = await connection.getDefaultNet();
      if (netHandle.netId == 0) {
        types.add(ConnectivityPlusPlugin.CONNECTIVITY_NONE);
        return types;
      }
      const capabilities = await connection.getNetCapabilities(netHandle);
      const bearerTypes = capabilities.bearerTypes;
      if (bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
        types.add(ConnectivityPlusPlugin.CONNECTIVITY_WIFI);
      }
      if (bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET)) {
        types.add(ConnectivityPlusPlugin.CONNECTIVITY_ETHERNET);
      }
      if (bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
        types.add(ConnectivityPlusPlugin.CONNECTIVITY_MOBILE);
      }
      if (bearerTypes.includes(connection.NetBearType.BEARER_BLUETOOTH)) {
        types.add(ConnectivityPlusPlugin.CONNECTIVITY_BLUETOOTH);
      }
      if (bearerTypes.includes(connection.NetBearType.BEARER_VPN)) {
        types.add(ConnectivityPlusPlugin.CONNECTIVITY_VPN);
      }
    } catch (e) {
      Log.e("ConnectivityPlusPlugin catch: ", e.message)
    }
    if (types.length == 0) {
      types.add(ConnectivityPlusPlugin.CONNECTIVITY_NONE);
    }
    return types;
  }
}
