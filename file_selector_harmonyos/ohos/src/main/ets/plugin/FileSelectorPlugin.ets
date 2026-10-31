import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { FileSelectorApiImpl } from './FileSelectorApiImpl'


export default class FileSelectorPlugin implements FlutterPlugin, AbilityAware {
  private pluginBinding: FlutterPluginBinding | null = null;
  private fileSelectorApi: FileSelectorApiImpl | null = null;

  getUniqueClassName(): string {
    return "FileSelectorPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = binding;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.fileSelectorApi = new FileSelectorApiImpl(binding);
    if (this.pluginBinding != null) {
      this.fileSelectorApi.setup(this.pluginBinding.getBinaryMessenger(), binding);
    }
  }

  onDetachedFromAbility(): void {
    this.fileSelectorApi = null;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = null;
  }
}