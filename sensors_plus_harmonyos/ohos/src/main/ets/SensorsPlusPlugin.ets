import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import EventChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import {
  AccelerometerStreamHandlerPlus,
  GyroscopeStreamHandlerPlus,
  MagnetometerStreamHandlerPlus,
  PressureStreamHandlerPlus,
  SensorStreamHandlerImpl,
  UserAccelerometerStreamHandlerPlus
} from './StreamHandlerPlus';

export default class SensorsPlusPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private METHOD_CHANNEL_NAME = "dev.fluttercommunity.plus/sensors/method";
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
  private accelerometerStreamHandler: SensorStreamHandlerImpl | undefined
  private userAccelerometerStreamHandler: SensorStreamHandlerImpl | undefined
  private gyroscopeStreamHandler: SensorStreamHandlerImpl | undefined
  private magnetometerStreamHandler: SensorStreamHandlerImpl | undefined
  private barometerStreamHandler: SensorStreamHandlerImpl | undefined

  getUniqueClassName(): string {
    return "SensorsPlusPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), this.METHOD_CHANNEL_NAME);
    this.channel.setMethodCallHandler(this)
    this.setupEventChannels(binding);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    this.accelerometerChannel?.setStreamHandler(null);
    this.userAccelerometerChannel?.setStreamHandler(null);
    this.gyroscopeChannel?.setStreamHandler(null);
    this.magnetometerChannel?.setStreamHandler(null);
    this.barometerChannel?.setStreamHandler(null);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    let streamHandler: SensorStreamHandlerImpl | undefined;
    switch (call.method) {
      case "setAccelerationSamplingPeriod":
        streamHandler = this.accelerometerStreamHandler;
        break;
      case "setUserAccelerometerSamplingPeriod":
        streamHandler = this.userAccelerometerStreamHandler;
        break;
      case "setGyroscopeSamplingPeriod":
        streamHandler = this.gyroscopeStreamHandler;
        break;
      case "setMagnetometerSamplingPeriod":
        streamHandler = this.magnetometerStreamHandler;
        break;
      case "setBarometerSamplingPeriod":
        streamHandler = this.barometerStreamHandler;
        break;
      default:
        streamHandler = undefined;
    }

    if (streamHandler) {
      streamHandler.samplingPeriod = call.args as number;
      result.success(null);
    } else {
      result.notImplemented();
    }
  }

  setupEventChannels(binding: FlutterPluginBinding): void {
    this.accelerometerChannel = new EventChannel(binding.getBinaryMessenger(), this.ACCELEROMETER_CHANNEL_NAME);
    this.accelerometerStreamHandler = AccelerometerStreamHandlerPlus();
    this.accelerometerChannel.setStreamHandler(this.accelerometerStreamHandler);

    this.userAccelerometerChannel =
      new EventChannel(binding.getBinaryMessenger(), this.USER_ACCELEROMETER_CHANNEL_NAME);
    this.userAccelerometerStreamHandler = UserAccelerometerStreamHandlerPlus();
    this.userAccelerometerChannel.setStreamHandler(this.userAccelerometerStreamHandler);

    this.gyroscopeChannel = new EventChannel(binding.getBinaryMessenger(), this.GYROSCOPE_CHANNEL_NAME);
    this.gyroscopeStreamHandler = GyroscopeStreamHandlerPlus();
    this.gyroscopeChannel.setStreamHandler(this.gyroscopeStreamHandler);

    this.magnetometerChannel = new EventChannel(binding.getBinaryMessenger(), this.MAGNETOMETER_CHANNEL_NAME);
    this.magnetometerStreamHandler = MagnetometerStreamHandlerPlus();
    this.magnetometerChannel.setStreamHandler(this.magnetometerStreamHandler);

    this.barometerChannel = new EventChannel(binding.getBinaryMessenger(), this.BAROMETER_CHANNEL_NAME);
    this.barometerStreamHandler = PressureStreamHandlerPlus();
    this.barometerChannel.setStreamHandler(this.barometerStreamHandler);
  }
}
