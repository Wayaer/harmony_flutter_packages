// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger,TaskQueue } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import {VideoPlayerApiCodec} from './VideoPlayerApiCodec.ets'
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';


/** Error class for passing custom error details to Flutter via a thrown PlatformException. */
export class FlutterError implements Error {

  /** The error code. */
  public code: string;

  /** The error name. */
  public name: string;

  /** The error message. */
  public message: string;
  /** The error stack. */
  public stack?: string;

  constructor(code: string, name: string,  message: string, stack: string) 
  {
    this.code = code;
    this.name = name;
    this.message = message;
    this.stack = stack;
  }
}

export function wrapError(error: Error): Array<Object> {
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

/* Pigeon equivalent of VideoViewType.*/
export enum PlatformVideoViewType {
  TEXTURE_VIEW,
  PLATFORM_VIEW
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class CreateMessage {
  private asset: string="";

  public getAsset(): string {
    return this.asset;
  }

  public setAsset(setterArg: string): void {
  this.asset = setterArg;
  }

  private uri: string="";

  public getUri(): string  {
    return this.uri;
  }

  public setUri(setterArg: string): void {
    this.uri = setterArg;
  }

  private packageName: String = "";

  public getPackageName(): String{
    return this.packageName;
  }

  public setPackageName(setterArg: String): void {
    this.packageName = setterArg;
  }

  private formatHint: String = "";

  public getFormatHint(): String {
    return this.formatHint;
  }

  public setFormatHint(setterArg: String): void {
    this.formatHint = setterArg;
  }

  private httpHeaders: Map<String, String>=new Map();

  public getHttpHeaders(): Map<String, String> {
    return this.httpHeaders;
  }

  public setHttpHeaders(setterArg: Map<String, String>): void {
    if (setterArg == null) {
      // throw new IllegalStateException("Nonnull field \"httpHeaders\" is null.");
    }
    this.httpHeaders = setterArg;
  }

  private viewType: PlatformVideoViewType=PlatformVideoViewType.TEXTURE_VIEW;

  public getViewType(): PlatformVideoViewType {
    return this.viewType;
  }

  public setViewType(viewTypeArg:PlatformVideoViewType){
    this.viewType=viewTypeArg;
  }

  toList(): Array<Object> {
    let arr: Array<Object> = new Array<Object>();
    arr.push(this.asset);
    arr.push(this.uri);
    arr.push(this.packageName);
    arr.push(this.formatHint);
    arr.push(this.httpHeaders);
    arr.push(this.viewType);
    return arr;
  }

  static fromList(list: Array<Object>): CreateMessage {
    let pigeonResult: CreateMessage = new CreateMessage();
    pigeonResult.setAsset(list[0] as string);
    pigeonResult.setUri(list[1] as string);
    pigeonResult.setPackageName(list[2] as String);
    pigeonResult.setFormatHint(list[3] as String);
    pigeonResult.setHttpHeaders(list[4] as Map<String, String>);
    pigeonResult.setViewType(list[5] as number);
    return pigeonResult;
  }
}

/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class OhosVideoPlayerApi {

  abstract initialize(): void;

  abstract create(msg: CreateMessage ): Promise<number>;

  abstract dispose(playerId: number ): void;

  abstract setLooping(playerId: number , looping: boolean ): void;

  abstract setVolume(playerId: number , volume: number ): void;

  abstract setPlaybackSpeed(playerId: number , speed: number ): void;

  abstract play(playerId: number ): void;

  abstract position(playerId: number ): number;

  abstract seekTo(playerId: number , position: number ): void;

  abstract pause(playerId: number ): void;

  abstract setMixWithOthers(mixWithOthers: boolean ): void;

  /** The codec used by OhosVideoPlayerApi. */
  static getCodec(): MessageCodec<Object>{
    return VideoPlayerApiCodec.INSTANCE;
  }

  /*Sets up an instance of `OhosVideoPlayerApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: OhosVideoPlayerApi | null): void {
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.initialize", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.initialize();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.create", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.create(args[0] as CreateMessage).catch((result:number)=>{
                  let output: number = result;
                  res.push(output);
                });
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.dispose", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.dispose(args[0] as number);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setLooping", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.setLooping(args[0] as number, args[1] as boolean);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setVolume", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.setVolume(args[0] as number, args[1] as number);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setPlaybackSpeed", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.setPlaybackSpeed(args[0] as number, args[1] as number);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.play", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.play(args[0] as number);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.position", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number = api!.position(args[0] as number);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.seekTo", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.seekTo(args[0] as number, args[1] as number);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.pause", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.pause(args[0] as number);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setMixWithOthers", OhosVideoPlayerApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.setMixWithOthers(args[0] as boolean);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
