// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import resourceManager from '@ohos.resourceManager';
import { VideoItem } from './VideoItem';
import { VideoSpeed } from './VideoSpeed';

export class CommonConstants {
  static readonly FULL_PERCENT: string = '100%';
  static readonly NINETY_PERCENT: string = '90%';
  static readonly FIFTY_PERCENT: string = '50%';
  static readonly PAGE: string = 'pages/PlayPage';
  static readonly TYPE_LOCAL: number = 0;
  static readonly TYPE_INTERNET: number = 1;
  static readonly STATUS_START: number = 1;
  static readonly STATUS_PAUSE: number = 2;
  static readonly STATUS_STOP: number = 3;
  static readonly ASPECT_RATIO: number = 1;
  static readonly ONE_HUNDRED: number = 100;
  static readonly A_THOUSAND: number = 1000;
  static readonly YES: string = 'yes';
  static readonly SPEED_ARRAY: VideoSpeed[] = [
    new VideoSpeed('0.75X', 0),
    new VideoSpeed('1.0X', 1),
    new VideoSpeed('1.25X', 2),
    new VideoSpeed('1.75X', 3),
    new VideoSpeed('2.0X', 4)
  ];
  static readonly TIME_UNIT: number = 60;
  static readonly INITIAL_TIME_UNIT: string = '00';
  static readonly PADDING_LENGTH: number = 2;
  static readonly PADDING_STR: string = '0';
  static readonly SCREEN_OFF: string = 'usual.event.SCREEN_OFF';
  static readonly OPERATE_STATE: Array<string> = ['prepared', 'playing', 'paused', 'completed'];
}

export enum AvplayerStatus {
  IDLE = 'idle',
  INITIALIZED = 'initialized',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  STOPPED = 'stopped',
  RELEASED = 'released',
  ERROR = 'error'
}

export enum Events {
  STATE_CHANGE = 'stateChange',
  TIME_UPDATE = 'timeUpdate',
  SEEK_DONE = 'seekDone',
  BUFFER_UPDATE = 'bufferingUpdate',
  ERROR = 'error'
}

export enum SliderMode {
  MOVING = 1,
  END = 2,
  CLICK = 3
}

export const VIDEO_DATA: VideoItem[] = [
  new VideoItem('video1', {} as resourceManager.RawFileDescriptor, 'video1.mp4',),
  new VideoItem('video2', {} as resourceManager.RawFileDescriptor, 'video2.mp4',)
]