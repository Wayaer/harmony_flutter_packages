import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { UrlLauncherApi } from './Messages';
import { UrlLauncher } from './UrlLauncher';

const TAG = "UrlLauncherPlugin"

export default class UrlLauncherPlugin implements FlutterPlugin, AbilityAware {
  private pluginBinding: FlutterPluginBinding | null = null;
  private urlLauncherApi: UrlLauncherApi | null = null;

  getUniqueClassName(): string {
    return TAG
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.urlLauncherApi = new UrlLauncher(binding.getAbility().context);
    this.urlLauncherApi.setup(
      this.pluginBinding?.getBinaryMessenger() ?? null, this.urlLauncherApi);
  }

  onDetachedFromAbility(): void {
    this.urlLauncherApi?.setup(null, null);
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = binding;
  }


  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.urlLauncherApi?.setup(this.pluginBinding?.getBinaryMessenger() ?? null, null);
    this.pluginBinding = null;
  }
}