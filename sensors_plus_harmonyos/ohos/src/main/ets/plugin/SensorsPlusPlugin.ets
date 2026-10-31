/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import EventChannel, { StreamHandler, EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos';
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import sensor from '@ohos.sensor';
import { BusinessError } from '@kit.BasicServicesKit';
import systemDateTime from '@ohos.systemDateTime';

class StreamHandlerImpl implements StreamHandler {
  private event: EventSink | null = null;
  private sensorId: sensor.SensorId;
  private currentInterval: number = 200000000;
  private isListening: boolean = false;

  constructor(sensorId: sensor.SensorId) {
    this.sensorId = sensorId;
  }

  private getSensorName(): string {
    switch (this.sensorId) {
      case sensor.SensorId.ACCELEROMETER:
        return 'Accelerometer';
      case sensor.SensorId.LINEAR_ACCELEROMETER:
        return 'User Accelerometer';
      case sensor.SensorId.GYROSCOPE:
        return 'Gyroscope';
      case sensor.SensorId.MAGNETIC_FIELD:
        return 'Magnetometer';
      case sensor.SensorId.BAROMETER:
        return 'Barometer';
      default:
        return 'Unknown';
    }
  }

  private startSensor(interval: number): void {
    // 尚未开始监听时只记录间隔，等 onListen 再真正订阅传感器
    if (this.event == null) {
      this.currentInterval = interval;
      return;
    }
    if (this.isListening && this.currentInterval === interval) {
      // 间隔未变且已在监听，无需重复注册
      return;
    }
    // 先取消旧监听，避免重复回调
    if (this.isListening) {
      const stopped: boolean = this.stopSensor();
      if (!stopped) {
        // 旧监听未成功取消，若继续注册会导致重复订阅。
        // 失败已通过 event.error 通知 Flutter，此处跳过本次注册。
        console.warn(`Stop ${this.getSensorName()} failed, skip re-subscribe`);
        return;
      }
    }
    try {
      let timestampMicroAtBoot = (systemDateTime.getTime(true) / 1000) -
        (systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, true) / 1000);
      switch (this.sensorId) {
        case sensor.SensorId.LINEAR_ACCELEROMETER:
          sensor.on(sensor.SensorId.LINEAR_ACCELEROMETER, (data: sensor.LinearAccelerometerResponse) => {
            this.sendLinearAccelerometerEvent(data, timestampMicroAtBoot);
          }, { interval: interval });
          break;
        case sensor.SensorId.ACCELEROMETER:
          sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
            this.sendAccelerometerEvent(data, timestampMicroAtBoot);
          }, { interval: interval });
          break;
        case sensor.SensorId.GYROSCOPE:
          sensor.on(sensor.SensorId.GYROSCOPE, (data: sensor.GyroscopeResponse) => {
            this.sendGyroscopeEvent(data, timestampMicroAtBoot);
          }, { interval: interval });
          break;
        case sensor.SensorId.MAGNETIC_FIELD:
          sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
            this.sendMagneticEvent(data, timestampMicroAtBoot);
          }, { interval: interval });
          break;
        case sensor.SensorId.BAROMETER:
          sensor.on(sensor.SensorId.BAROMETER, (data: sensor.BarometerResponse) => {
            this.sendBarometerEvent(data, timestampMicroAtBoot);
          }, { interval: interval });
          break;
        default:
          if (this.event) {
            this.event.error('UNKNOWN_SENSOR', `Sensor type not supported: ${this.sensorId}`, null);
          }
          return;
      }
      // sensor.on() 成功后才更新状态
      this.currentInterval = interval;
      this.isListening = true;
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`Failed to invoke on. Code: ${e.code}, message: ${e.message}`);
      if (this.event) {
        this.event.error('UNAVAILABLE', `Failed to subscribe to ${this.getSensorName()}: ${e.code} - ${e.message}`, null);
      }
    }
  }

  /**
   * 停止传感器监听，返回是否成功取消；失败时保持 isListening 并已通过 event.error 通知 Flutter 层。
   */
  private stopSensor(): boolean {
    if (!this.isListening) {
      return true;
    }
    try {
      switch (this.sensorId) {
        case sensor.SensorId.ACCELEROMETER:
          sensor.off(sensor.SensorId.ACCELEROMETER);
          break;
        case sensor.SensorId.LINEAR_ACCELEROMETER:
          sensor.off(sensor.SensorId.LINEAR_ACCELEROMETER);
          break;
        case sensor.SensorId.GYROSCOPE:
          sensor.off(sensor.SensorId.GYROSCOPE);
          break;
        case sensor.SensorId.MAGNETIC_FIELD:
          sensor.off(sensor.SensorId.MAGNETIC_FIELD);
          break;
        case sensor.SensorId.BAROMETER:
          sensor.off(sensor.SensorId.BAROMETER);
          break;
        default:
          break;
      }
      // 成功取消监听后才更新状态
      this.isListening = false;
      return true;
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`Failed to invoke off. Code: ${e.code}, message: ${e.message}`);
      if (this.event) {
        this.event.error('UNAVAILABLE', `Failed to unsubscribe ${this.getSensorName()}: ${e.code} - ${e.message}`, null);
      }
      // 失败：保留 isListening 状态，表示监听可能仍在，避免状态与实际不一致
      return false;
    }
  }

  /**
   * Ability 销毁/退后台时停止监听但保留 event sink，释放传感器资源，Flutter 重新订阅时可恢复。
   */
  stopForAbilityDetach(): void {
    this.stopSensor();
  }

  resumeAfterAbilityAttach(): void {
    if (this.event != null) {
      this.startSensor(this.currentInterval);
    }
  }

  private sendLinearAccelerometerEvent(data: sensor.LinearAccelerometerResponse, timestampMicroAtBoot: number): void {
    try {
      if (this.event) {
        let arr: Array<number> = [4];
        let timestampMicro = timestampMicroAtBoot + data.timestamp / 1000;
        arr[0] = data.x;
        arr[1] = data.y;
        arr[2] = data.z;
        arr[3] = timestampMicro;
        if (Number.isInteger(data.x)) {
          arr[0] = data.x + 0.00000000001;
        }
        if (Number.isInteger(data.y)) {
          arr[1] = data.y + 0.00000000001;
        }
        if (Number.isInteger(data.z)) {
          arr[2] = data.z + 0.00000000001;
        }
        if (Number.isInteger(timestampMicro)) {
          arr[3] = timestampMicro + 0.5;
        }
        this.event.success(arr);
      }
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`sendLinearAccelerometerEvent error: ${e.code}, ${e.message}`);
    }
  }

  private sendAccelerometerEvent(data: sensor.AccelerometerResponse, timestampMicroAtBoot: number): void {
    try {
      if (this.event) {
        let arr: Array<number> = [4];
        let timestampMicro = timestampMicroAtBoot + data.timestamp / 1000;
        arr[0] = data.x;
        arr[1] = data.y;
        arr[2] = data.z;
        arr[3] = timestampMicro;
        if (Number.isInteger(data.x)) {
          arr[0] = data.x + 0.00000000001;
        }
        if (Number.isInteger(data.y)) {
          arr[1] = data.y + 0.00000000001;
        }
        if (Number.isInteger(data.z)) {
          arr[2] = data.z + 0.00000000001;
        }
        if (Number.isInteger(timestampMicro)) {
          arr[3] = timestampMicro + 0.5;
        }
        this.event.success(arr);
      }
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`sendAccelerometerEvent error: ${e.code}, ${e.message}`);
    }
  }

  private sendGyroscopeEvent(data: sensor.GyroscopeResponse, timestampMicroAtBoot: number): void {
    try {
      if (this.event) {
        let arr: Array<number> = [4];
        let timestampMicro = timestampMicroAtBoot + data.timestamp / 1000;
        arr[0] = data.x;
        arr[1] = data.y;
        arr[2] = data.z;
        arr[3] = timestampMicro;
        if (Number.isInteger(data.x)) {
          arr[0] = data.x + 0.00000000001;
        }
        if (Number.isInteger(data.y)) {
          arr[1] = data.y + 0.00000000001;
        }
        if (Number.isInteger(data.z)) {
          arr[2] = data.z + 0.00000000001;
        }
        if (Number.isInteger(timestampMicro)) {
          arr[3] = timestampMicro + 0.5;
        }
        this.event.success(arr);
      }
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`sendGyroscopeEvent error: ${e.code}, ${e.message}`);
    }
  }

  private sendMagneticEvent(data: sensor.MagneticFieldResponse, timestampMicroAtBoot: number): void {
    try {
      if (this.event) {
        let arr: Array<number> = [4];
        let timestampMicro = timestampMicroAtBoot + data.timestamp / 1000;
        arr[0] = data.x;
        arr[1] = data.y;
        arr[2] = data.z;
        arr[3] = timestampMicro;
        if (Number.isInteger(data.x)) {
          arr[0] = data.x + 0.00000000001;
        }
        if (Number.isInteger(data.y)) {
          arr[1] = data.y + 0.00000000001;
        }
        if (Number.isInteger(data.z)) {
          arr[2] = data.z + 0.00000000001;
        }
        if (Number.isInteger(timestampMicro)) {
          arr[3] = timestampMicro + 0.5;
        }
        this.event.success(arr);
      }
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`sendMagneticEvent error: ${e.code}, ${e.message}`);
    }
  }

  private sendBarometerEvent(data: sensor.BarometerResponse, timestampMicroAtBoot: number): void {
    try {
      if (this.event) {
        let arr: Array<number> = [2];
        let timestampMicro = timestampMicroAtBoot + data.timestamp / 1000;
        arr[0] = data.pressure;
        arr[1] = timestampMicro;
        if (Number.isInteger(data.pressure)) {
          arr[0] = data.pressure + 0.00000000001;
        }
        if (Number.isInteger(timestampMicro)) {
          arr[1] = timestampMicro + 0.5;
        }
        this.event.success(arr);
      }
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`sendBarometerEvent error: ${e.code}, ${e.message}`);
    }
  }

  setUpdateInterval(interval: number) {
    if (typeof interval !== 'number' || interval < 0) {
      console.error(`Invalid interval value: ${interval}, must be a non-negative number`);
      return;
    }
    switch (interval) {
      case 20000:
        this.startSensor(20000000);
        break;
      case 66667:
        this.startSensor(66667000);
        break;
      case 200000:
        this.startSensor(200000000);
        break;
      case 500000:
        this.startSensor(500000000);
        break;
      case 1000000:
        this.startSensor(1000000000);
        break;
      default:
        this.startSensor(interval * 1000);
        break;
    }
  }

  onListen(args: ESObject, events: EventSink): void {
    this.event = events;
    // Flutter 开始监听时才启动传感器。
    // 可用性检查由 startSensor 内的 try-catch 完成：sensor.on() 订阅失败
    // （传感器不存在或权限不足）会通过 event.error('UNAVAILABLE') 通知 Flutter。
    this.startSensor(this.currentInterval);
  }

  onCancel(args: ESObject): void {
    // Flutter 停止监听，取消传感器订阅
    this.stopSensor();
    this.event = null;
  }
}

export default class SensorsPlusPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  // 当前绑定的 Ability（AbilityAware 生命周期），用于按 Ability 生命周期管理传感器资源
  private abilityBinding: AbilityPluginBinding | null = null;

  private ACCELEROMETER_CHANNEL_NAME = 'dev.fluttercommunity.plus/sensors/accelerometer';
  private USER_ACCELEROMETER_CHANNEL_NAME = 'dev.fluttercommunity.plus/sensors/user_accel';
  private GYROSCOPE_CHANNEL_NAME = 'dev.fluttercommunity.plus/sensors/gyroscope';
  private MAGNETOMETER_CHANNEL_NAME = 'dev.fluttercommunity.plus/sensors/magnetometer';
  private BAROMETER_CHANNEL_NAME = 'dev.fluttercommunity.plus/sensors/barometer';

  private accelerometerChannel: EventChannel | null = null;
  private gyroscopeChannel: EventChannel | null = null;
  private magnetometerChannel: EventChannel | null = null;
  private userAccelerometerChannel: EventChannel | null = null;
  private barometerChannel: EventChannel | null = null;

  private accelerationStreamHandler: StreamHandlerImpl | null = null;
  private gyroScopeStreamHandler: StreamHandlerImpl | null = null;
  private magnetometerStreamHandler: StreamHandlerImpl | null = null;
  private userAccelerationStreamHandler: StreamHandlerImpl | null = null;
  private barometerStreamHandler: StreamHandlerImpl | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'SensorsPlusPlugin';
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityBinding = binding;
    this.accelerationStreamHandler?.resumeAfterAbilityAttach();
    this.userAccelerationStreamHandler?.resumeAfterAbilityAttach();
    this.gyroScopeStreamHandler?.resumeAfterAbilityAttach();
    this.magnetometerStreamHandler?.resumeAfterAbilityAttach();
    this.barometerStreamHandler?.resumeAfterAbilityAttach();
  }

  onDetachedFromAbility(): void {
    // 停止所有活跃的传感器监听，保留 event sink，Flutter 重新订阅时可恢复
    this.accelerationStreamHandler?.stopForAbilityDetach();
    this.userAccelerationStreamHandler?.stopForAbilityDetach();
    this.gyroScopeStreamHandler?.stopForAbilityDetach();
    this.magnetometerStreamHandler?.stopForAbilityDetach();
    this.barometerStreamHandler?.stopForAbilityDetach();
    // 清空 Ability 引用，避免泄漏 UIAbility
    this.abilityBinding = null;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'dev.fluttercommunity.plus/sensors/method');
    this.channel.setMethodCallHandler(this)
    this.setupEventChannels(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.accelerationStreamHandler?.onCancel(null);
    this.userAccelerationStreamHandler?.onCancel(null);
    this.gyroScopeStreamHandler?.onCancel(null);
    this.magnetometerStreamHandler?.onCancel(null);
    this.barometerStreamHandler?.onCancel(null);
    this.accelerometerChannel?.setStreamHandler(null);
    this.userAccelerometerChannel?.setStreamHandler(null);
    this.gyroscopeChannel?.setStreamHandler(null);
    this.magnetometerChannel?.setStreamHandler(null);
    this.barometerChannel?.setStreamHandler(null);
    this.accelerationStreamHandler = null;
    this.userAccelerationStreamHandler = null;
    this.gyroScopeStreamHandler = null;
    this.magnetometerStreamHandler = null;
    this.barometerStreamHandler = null;
    this.accelerometerChannel = null;
    this.userAccelerometerChannel = null;
    this.gyroscopeChannel = null;
    this.magnetometerChannel = null;
    this.barometerChannel = null;
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
      this.channel = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      let interval: number = call.args as number;
      if (typeof interval !== 'number' || interval < 0) {
        result.error('INVALID_ARGUMENT', `Expected non-negative number for interval, got: ${interval}`, null);
        return;
      }
      switch (call.method) {
        case 'setAccelerationSamplingPeriod':
          this.accelerationStreamHandler?.setUpdateInterval(interval);
          break;
        case 'setGyroscopeSamplingPeriod':
          this.gyroScopeStreamHandler?.setUpdateInterval(interval);
          break;
        case 'setUserAccelerometerSamplingPeriod':
          this.userAccelerationStreamHandler?.setUpdateInterval(interval);
          break;
        case 'setMagnetometerSamplingPeriod':
          this.magnetometerStreamHandler?.setUpdateInterval(interval);
          break;
        case 'setBarometerSamplingPeriod':
          this.barometerStreamHandler?.setUpdateInterval(interval);
          break;
        default:
          result.notImplemented();
          return;
      }
      result.success(null);
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`onMethodCall error. Code: ${e.code}, message: ${e.message}`);
      result.error('METHOD_CALL_ERROR', `Unexpected error: ${e.code} - ${e.message}`, null);
    }
  }

  private setupEventChannels(context: Context, messenger: BinaryMessenger) {
    this.userAccelerometerChannel = new EventChannel(messenger, this.USER_ACCELEROMETER_CHANNEL_NAME);
    this.userAccelerationStreamHandler = new StreamHandlerImpl(sensor.SensorId.LINEAR_ACCELEROMETER);
    this.userAccelerometerChannel.setStreamHandler(this.userAccelerationStreamHandler);

    this.accelerometerChannel = new EventChannel(messenger, this.ACCELEROMETER_CHANNEL_NAME);
    this.accelerationStreamHandler = new StreamHandlerImpl(sensor.SensorId.ACCELEROMETER);
    this.accelerometerChannel.setStreamHandler(this.accelerationStreamHandler);

    this.magnetometerChannel = new EventChannel(messenger, this.MAGNETOMETER_CHANNEL_NAME);
    this.magnetometerStreamHandler = new StreamHandlerImpl(sensor.SensorId.MAGNETIC_FIELD);
    this.magnetometerChannel.setStreamHandler(this.magnetometerStreamHandler);

    this.gyroscopeChannel = new EventChannel(messenger, this.GYROSCOPE_CHANNEL_NAME);
    this.gyroScopeStreamHandler = new StreamHandlerImpl(sensor.SensorId.GYROSCOPE);
    this.gyroscopeChannel.setStreamHandler(this.gyroScopeStreamHandler);

    this.barometerChannel = new EventChannel(messenger, this.BAROMETER_CHANNEL_NAME);
    this.barometerStreamHandler = new StreamHandlerImpl(sensor.SensorId.BAROMETER);
    this.barometerChannel.setStreamHandler(this.barometerStreamHandler);
  }
}
