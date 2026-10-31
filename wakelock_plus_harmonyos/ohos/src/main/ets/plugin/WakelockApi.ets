/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
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

import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger, TaskQueue } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';
import { HashMap } from '@kit.ArkTS';

export class FlutterError implements Error {
  public code: string;
  public name: string;
  public message: string;
  public stack?: string;

  constructor(code: string, name: string, message: string, stack: string) {
    this.code = code;
    this.name = name;
    this.message = message;
    this.stack = stack;
  }
}

function wrapError(error: Error): Array<Object> {
  let errorList: Array<Object> = new Array<Object>(3);
  if (error instanceof FlutterError) {
    let err: FlutterError = error as FlutterError;
    errorList[0] = err.code;
    errorList[1] = err.name;
    errorList[2] = err.message;
  } else {
    errorList[0] = error.toString();
    errorList[1] = error.name;
    errorList[2] = "Cause: " + error.message + ", Stacktrace: " + error.stack;
  }
  return errorList;
}

export class ToggleMessage {
  private enable: boolean;

  getEnable(): boolean {
    return this.enable;
  }

  constructor(enable: boolean) {
    this.enable = enable;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    arr.push(this.enable);
    return arr;
  }

  static fromList(message: Object): ToggleMessage {
    let  list:Array<Object> = message as Array<Object>;
    let instance: ToggleMessage = new ToggleMessage(list[0] as boolean);
    return instance;
  }
}

export class IsEnabledMessage {
  private enabled: boolean;

  getEnabled(): boolean {
    return this.enabled;
  }

  constructor(enabled: boolean) {
    this.enabled = enabled;
  }

  toList(): Array<Object> {
    let result: Array<Object> = [];
    result.push(this.enabled);
    return result;
  }

  static fromList(message: Object): IsEnabledMessage {
    let list: Array<Object> = message as Array<Object>;
    let instance: IsEnabledMessage = new IsEnabledMessage(list[0] as boolean);
    return instance;
  }
}

class WakelockApiCodec extends StandardMessageCodec {
  static INSTANCE: WakelockApiCodec = new WakelockApiCodec();

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
      case 129:
        return ToggleMessage.fromList(super.readValue(buffer));
      case 130:
        return IsEnabledMessage.fromList(super.readValue(buffer));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof IsEnabledMessage) {
      stream.writeInt8(130);
      this.writeValue(stream, (value as IsEnabledMessage).toList());
    } else if (value instanceof ToggleMessage) {
      stream.writeInt8(129);
      this.writeValue(stream, (value as ToggleMessage).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class WakelockApi {
  abstract toggle(msg: ToggleMessage): Promise<void>;

  abstract isEnabled(): Promise<IsEnabledMessage>;

  static getCodec(): MessageCodec<Object> {
    return WakelockApiCodec.INSTANCE;
  }

  static setup(binaryMessenger: BinaryMessenger, api: WakelockApi | null): void {
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle", WakelockApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          async onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              await api!.toggle(args[0] as ToggleMessage);
              res.push(null);
            }
            catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.isEnabled", WakelockApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          async onMessage(message: Object, reply: Reply<Object>) {
            try {
              let output: IsEnabledMessage = await api!.isEnabled();
              reply.reply([output]);
            }
            catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              reply.reply(wrappedError);
            }
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
