import common from '@ohos.app.ability.common';
import { ErrorCallback } from './ErrorCallback';
import PermissionConstants from './PermissionConstants';
import locationManager from '@ohos.geoLocationManager';
import bluetoothManager from '@ohos.bluetoothManager';
import sim from '@ohos.telephony.sim';

export class ServiceManager {
  checkServiceStatus(permission: number, context: common.Context,
    successCallback: SuccessCallback, errorCallback: ErrorCallback): void {
    if (permission == PermissionConstants.PERMISSION_GROUP_LOCATION ||
      permission == PermissionConstants.PERMISSION_GROUP_LOCATION_ALWAYS ||
      permission == PermissionConstants.PERMISSION_GROUP_LOCATION_WHEN_IN_USE) {
      successCallback.onSuccess(this.isLocationServiceEnable()
        ? PermissionConstants.SERVICE_STATUS_ENABLED : PermissionConstants.SERVICE_STATUS_DISABLED);
      return;
    }
    if (permission == PermissionConstants.PERMISSION_GROUP_BLUETOOTH) {
      successCallback.onSuccess(this.isBluetoothServiceEnable()
        ? PermissionConstants.SERVICE_STATUS_ENABLED : PermissionConstants.SERVICE_STATUS_DISABLED);
      return;
    }
    if (permission == PermissionConstants.PERMISSION_GROUP_PHONE) {
      try {
        sim.getSimState(0).then((state) => {
          if (state == sim.SimState.SIM_STATE_READY) {
            successCallback.onSuccess(PermissionConstants.SERVICE_STATUS_ENABLED);
            return;
          }
          sim.getSimState(1).then((stateSimTwo) => {
            if (stateSimTwo == sim.SimState.SIM_STATE_READY) {
              successCallback.onSuccess(PermissionConstants.SERVICE_STATUS_ENABLED);
              return;
            }
            successCallback.onSuccess(PermissionConstants.SERVICE_STATUS_DISABLED);
          });
        });
      } catch (error) {
        successCallback.onSuccess(PermissionConstants.SERVICE_STATUS_DISABLED);
      }
      return;
    }
    if (permission == PermissionConstants.PERMISSION_GROUP_IGNORE_BATTERY_OPTIMIZATIONS) {
      successCallback.onSuccess(PermissionConstants.SERVICE_STATUS_DISABLED);
      return;
    }
    successCallback.onSuccess(PermissionConstants.SERVICE_STATUS_NOT_APPLICABLE);
  }

  private isLocationServiceEnable(): boolean {
    try {
      return locationManager.isLocationEnabled();
    } catch (error) {
      return false;
    }
  }

  private isBluetoothServiceEnable(): boolean {
    try {
      return bluetoothManager.getState() == bluetoothManager.BluetoothState.STATE_ON;
    } catch (error) {
      return false;
    }
  }
}

export interface SuccessCallback {
  onSuccess(serviceStatus: number): void;
}