import { StreamHandler, EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { ArrayList } from '@kit.ArkTS';
import ConnectivityPlusPlugin from './ConnectivityPlusPlugin';

export class ConnectivityBroadcastReceiver implements StreamHandler {
  private events: EventSink | null = null;

  onListen(args: Object, events: EventSink): void {
    this.events = events;
    ConnectivityPlusPlugin.netConnection.register(async () => {
      this.sendEvent(await ConnectivityPlusPlugin.getNetworkType())
    })

    //订阅网络可用事件。
    ConnectivityPlusPlugin.netConnection.on('netAvailable', async (data) => {
      this.sendEvent(await ConnectivityPlusPlugin.getNetworkType())
    })

    //订阅网络能力变化事件。
    ConnectivityPlusPlugin.netConnection.on('netCapabilitiesChange', async (data) => {
      this.sendEvent(await ConnectivityPlusPlugin.getNetworkType())
    })

    //订阅网络连接信息变化事件
    ConnectivityPlusPlugin.netConnection.on('netConnectionPropertiesChange', async (data) => {
      this.sendEvent(await ConnectivityPlusPlugin.getNetworkType())
    })

    //订阅网络订阅网络丢失事件。
    ConnectivityPlusPlugin.netConnection.on('netLost', () => {
      const types: ArrayList<String> = new ArrayList();
      types.add(ConnectivityPlusPlugin.CONNECTIVITY_NONE);
      this.sendEvent(types)
    })

    //订阅网络不可用事件。
    ConnectivityPlusPlugin.netConnection.on('netUnavailable', () => {
      const types: ArrayList<String> = new ArrayList();
      types.add(ConnectivityPlusPlugin.CONNECTIVITY_NONE);
      this.sendEvent(types)
    })

  }

  onCancel(): void {
    ConnectivityPlusPlugin.netConnection.unregister(() => {
    })
  }

  private sendEvent(networkType: ArrayList<String>) {
    this.events?.success(networkType);
  }
}


