import common from '@ohos.app.ability.common';
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { AppSettingManager } from './AppSettingManager';
import { MethodCallHandlerImpl } from './MethodCallHandlerImpl';
import { PermissionManager } from './PermissionManager';
import { ServiceManager } from './ServiceManager';

export default class PermissionHandlerPlugin implements FlutterPlugin, AbilityAware {
  private permissionManager: PermissionManager;
  private methodChannel: MethodChannel | null = null;
  private methodCallHandler: MethodCallHandlerImpl | null = null;
  private pluginBinding: AbilityPluginBinding | null = null;

  constructor() {
    this.permissionManager = new PermissionManager();
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.pluginBinding = binding;
    this.startListeningToAbility(this.pluginBinding.getAbility());
  }

  onDetachedFromAbility(): void {
    this.stopListeningToAbility();
  }

  getUniqueClassName(): string {
    return 'PermissionHandlerPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.startListening(binding?.getApplicationContext(), binding?.getBinaryMessenger());
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.stopListening();
  }

  private startListening(context: common.Context, message: BinaryMessenger): void {
    this.methodChannel =
      new MethodChannel(message, 'flutter.baseflow.com/permissions/methods', StandardMethodCodec.INSTANCE);
    this.methodCallHandler = new MethodCallHandlerImpl(context, new AppSettingManager(),
      this.permissionManager, new ServiceManager());
    this.methodChannel.setMethodCallHandler(this.methodCallHandler);
  }

  private stopListening(): void {
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
    this.methodCallHandler = null;
  }

  private startListeningToAbility(ability: UIAbility): void {
    if (this.methodCallHandler != null) {
      this.methodCallHandler.setAbility(ability);
    }
  }

  private stopListeningToAbility(): void {
    if (this.methodCallHandler != null) {
      this.methodCallHandler.setAbility(null);
    }
  }
}