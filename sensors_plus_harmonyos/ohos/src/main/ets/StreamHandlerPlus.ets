import { systemDateTime } from '@kit.BasicServicesKit';
import { Any, EventSink, Log, StreamHandler } from '@ohos/flutter_ohos';
import { sensor } from '@kit.SensorServiceKit';

const timestampMicroAtBoot: number = systemDateTime.getTime();

const TAG = "StreamHandlerImpl"

function transformData(x: number, y: number, z: number, timestamp: number): number[] {
  const timestampSince1970Micro: number = timestampMicroAtBoot + timestamp / 1000;
  const data = [
    Number.isInteger(x) ? x + 0.00000000001 : x,
    Number.isInteger(y) ? y + 0.00000000001 : y,
    Number.isInteger(z) ? z + 0.00000000001 : z,
    Number.isInteger(timestampSince1970Micro) ? timestampSince1970Micro + 0.00000000001 : timestampSince1970Micro
  ];
  return data;
}

export abstract class StreamHandlerImpl implements StreamHandler {
  protected sensorId: number;
  protected events: EventSink | null = null;
  // 默认 200 ms
  protected _samplingPeriod: number = 200000;

  set samplingPeriod(value: number) {
    this._samplingPeriod = value;
    this.didUpdateSamplingPeriod();
  }

  get samplingPeriod(): number {
    return this._samplingPeriod;
  }

  constructor(sensorId: number) {
    this.sensorId = sensorId;
  }

  get samplingPeriodInNanos(): number {
    return this._samplingPeriod * 1000;
  }

  protected subscribeSensor(sensorId: number, callback: (response: sensor.Response) => void): void {
    try {
      sensor.on(sensorId, callback, { interval: this.samplingPeriodInNanos });
    } catch (error) {
      Log.e(TAG, 'Failed to invoke on. Code:' + error.code + " message:" + error.message)
    }
  }

  protected unsubscribeSensor(sensorId: number, callback: (response: sensor.Response) => void): void {
    sensor.off(sensorId, callback);
    this.events = null;
  }

  protected updateSensor(sensorId: number, callback: (response: sensor.Response) => void): void {
    sensor.off(sensorId, callback);
    sensor.on(sensorId, callback, { interval: this.samplingPeriodInNanos });
  }

  abstract onListen(args: Any, events: EventSink): void

  abstract onCancel(args: Any): void

  abstract didUpdateSamplingPeriod(): void
}

export class SensorStreamHandlerImpl extends StreamHandlerImpl {
  private readonly eventTransformer: (response: sensor.Response) => number[];

  constructor(sensorId: number, eventTransformer: (response: sensor.Response) => number[]) {
    super(sensorId)
    this.eventTransformer = eventTransformer;
  }

  onListen(args: Any, events: EventSink): void {
    this.events = events;
    this.subscribeSensor(this.sensorId, this.callback)
  }

  onCancel(args: Any): void {
    this.unsubscribeSensor(this.sensorId, this.callback);
  }

  didUpdateSamplingPeriod(): void {
    this.updateSensor(this.sensorId, this.eventTransformer);
  }

  private callback = (response: sensor.Response) => {
    if (this.events === null) {
      Log.e(TAG, "events is null");
      return;
    }
    const data = this.eventTransformer(response);
    this.events.success(data);
  };
}

export const AccelerometerStreamHandlerPlus = () => new SensorStreamHandlerImpl(
  sensor.SensorId.ACCELEROMETER,
  (response: sensor.Response) => {
    const resp = response as sensor.AccelerometerResponse;
    return transformData(resp.x, resp.y, resp.z, resp.timestamp);
  }
);

export const UserAccelerometerStreamHandlerPlus = () => new SensorStreamHandlerImpl(
  sensor.SensorId.LINEAR_ACCELEROMETER,
  (response: sensor.Response) => {
    const resp = response as sensor.LinearAccelerometerResponse;
    return transformData(resp.x, resp.y, resp.z, resp.timestamp);
  }
);

export const GyroscopeStreamHandlerPlus = () => new SensorStreamHandlerImpl(
  sensor.SensorId.GYROSCOPE,
  (response: sensor.Response) => {
    const resp = response as sensor.GyroscopeResponse;
    return transformData(resp.x, resp.y, resp.z, resp.timestamp);
  }
);

export const MagnetometerStreamHandlerPlus = () => new SensorStreamHandlerImpl(
  sensor.SensorId.MAGNETIC_FIELD,
  (response: sensor.Response) => {
    const resp = response as sensor.MagneticFieldResponse;
    return transformData(resp.x, resp.y, resp.z, resp.timestamp);
  }
);

export const PressureStreamHandlerPlus = () => new SensorStreamHandlerImpl(
  sensor.SensorId.BAROMETER,
  (response: sensor.Response) => {
    const resp = response as sensor.BarometerResponse;
    const pressure = resp.pressure;
    const timestampSince1970Micro = timestampMicroAtBoot + resp.timestamp / 1000;
    return [
      Number.isInteger(pressure) ? pressure + 0.00000000001 : pressure,
      Number.isInteger(timestampSince1970Micro) ? timestampSince1970Micro + 0.00000000001 : timestampSince1970Micro
    ]
  }
);
