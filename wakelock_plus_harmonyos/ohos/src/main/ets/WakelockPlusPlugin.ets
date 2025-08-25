import {
  AbilityAware, AbilityPluginBinding, FlutterPlugin, FlutterPluginBinding, Log,
} from '@ohos/flutter_ohos';
import { IsEnabledMessage, ToggleMessage, WakelockApi } from './WakelockApi';
import window from '@ohos.window';
import { Context } from '@ohos.abilityAccessCtrl';

const TAG = "WakelockPlusPlugin"

export default class WakelockPlusPlugin extends WakelockApi implements FlutterPlugin, AbilityAware {
  private context: Context | null = null;

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    WakelockApi.setup(binding.getBinaryMessenger(), this);
  }


  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.context = null;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    WakelockApi.setup(binding.getBinaryMessenger(), null);
  }

  async toggle(msg: ToggleMessage): Promise<void> {
    try {
      if (this.context != null) {
        let windowClass = await window.getLastWindow(this.context);
        await windowClass.setWindowKeepScreenOn(msg.getEnable());
      }
    } catch (err) {
      Log.d(TAG, 'toggle failed, err: ' + err);
    }
  }

  async isEnabled(): Promise<IsEnabledMessage> {
    let isEnabled = false;
    try {
      if (this.context != null) {
        let windowClass = await window.getLastWindow(this.context);
        isEnabled = windowClass.getWindowProperties().isKeepScreenOn;
      }
    } catch (err) {
      Log.d(TAG, 'isEnabled err: ' + err);
    }
    return new IsEnabledMessage(isEnabled);
  }
}