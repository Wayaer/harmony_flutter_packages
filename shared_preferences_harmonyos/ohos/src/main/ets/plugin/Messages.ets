// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on Messages.java originally written by
// Copyright 2013 The Flutter Authors.

import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';

export class FlutterError extends Error {
  public code: string;

  public details: Object;

  constructor(code: string, message: string, details: Object) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

export function wrapError(exception: Error): Array<Object> {
  let errorList = new Array<Object>();
  if (exception instanceof FlutterError) {
    let error = exception as FlutterError;
    errorList.push(error.code);
    errorList.push(error.message);
    errorList.push(error.details);
  } else {
    errorList.push(exception.toString());
    errorList.push(exception.name);
    errorList.push(
      "Cause: " + exception.message + ", Stacktrace: " + exception.stack);
  }
  return errorList;
}

export interface SharedPreferencesApi {
  remove(key: string): boolean;

  setBool(key: string, value: boolean): Promise<void>;

  setString(key: string, value: string): Promise<void>;

  setInt(key: string, value: bigint): Promise<void>;

  setDouble(key: string, value: number): Promise<void>;

  setEncodedStringList(key: string, value: string): Promise<void>;

  setDeprecatedStringList(key: string, value: Array<string>): Promise<void>;

  clear(prefix: string, allowList: Array<string> | null): Promise<void>;

  getAll(prefix: string, allowList: Array<string> | null): Promise<Object>;

  getCodec(): MessageCodec<Object>;

  setup(messenger: BinaryMessenger, api: SharedPreferencesApi): void;
}