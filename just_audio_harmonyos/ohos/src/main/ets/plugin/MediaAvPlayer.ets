/**
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * */

import { media } from '@kit.MediaKit';
import { common, wantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AVCastPickerState, avSession } from '@kit.AVSessionKit';
import { audio } from '@kit.AudioKit';
import MediaSource from './MediaSource';
import { fileIo } from '@kit.CoreFileKit';
import { Log, MethodResult } from '@ohos/flutter_ohos';

const TAG = 'MediaAvPlayer';
const OPERATE_ERROR: number = 801;
const AVPLAYER_STATE_ERROR: number = 5400102;

export enum AudioPlayerState {
  IDLE,
  INITIALIZED,
  LOAD,
  PREPARED,
  PLAY,
  PAUSE,
  STOP,
  ERROR,
  COMPLETED,
  RELEASED,
  PROGRESS_SPEED,
  TIME_UPDATE,
  VOLUME_CHANGE,
  UNKNOWN
}

export enum LoopMode {
  DEFAULT,
  SINGLE_CYCLE,
  LIST_LOOP
}

enum SeekMode {
  UNKNOWN,
  SEEK,
  FINISH
}

export enum PlaybackState {
  IDLE, STATE_READY, STATE_BUFFERING, STATE_ENDED, STATE_PLAY
}

export interface onChangeMediaAvPlayerState {
  onPlaybackStateChanged(state: PlaybackState): void;

  onUpdateCurrentIndex(updateIndex: number): void;

  onUpdatePosition(updatePosition: number): void;

  onUpdateBufferedPosition(bufferedPosition: number): void;

  onAudioSessionIdChanged(audioSessionId: number): void;

  broadcastImmediatePlaybackEvent(): void;

  completeSeek(): void;

  completeInitial(): void;

  onStartBuffering(): void;

  onEndBuffering(): void;

  setAudioSessionId(audioSessionId: number): void

  onErrorCallback(err: BusinessError): void

  onAudioFocusChanged(isPlaying: boolean): void
}

export class MediaAvPlayer {
  private context: common.UIAbilityContext | undefined = AppStorage.get('context');
  public avPlayer: media.AVPlayer | null = null;
  public avPlayerNext: media.AVPlayer | null = null;
  public isPlaying: boolean = false;
  public songList: MediaSource[] = [];
  public state: AudioPlayerState = AudioPlayerState.IDLE;
  private session?: avSession.AVSession;
  private initialPos: number = -1;
  private initialIndex: number = -1;
  private volume: number = -1;
  private speed: number = 1;
  private seekModule: SeekMode = SeekMode.UNKNOWN;
  private playMode: LoopMode = LoopMode.DEFAULT;
  private isFirst: boolean = true;
  private isPrepared: boolean = false;
  private isClipping: boolean = false;
  private isPreBuffering: boolean = false;
  private isRandom: boolean = false;
  private musicIndex: number = 0;
  private preMusicIndex: number = 0;
  private songItem: MediaSource | null = null;
  private shuffleOrder: number[] = [];
  private avMetadataExtractor: media.AVMetadataExtractor | null = null;
  private avMetadata?: media.AVMetadata;
  // 追踪通过 fileIo.openSync 打开的文件描述符（uri -> fd），避免加载 file:// 音源时泄漏 fd
  private fdMap: Map<string, number> = new Map<string, number>();
  public mediaAvPlayerStateChangeListener?: onChangeMediaAvPlayerState;
  // 播放策略
  private playStrategy: media.PlaybackStrategy = {
    //播放策略首选宽度，int类型，如1080。
    preferredWidth: 1,
    //播放策略首选高度，int类型，如1920。
    preferredHeight: 2,
    //播放策略首选缓冲持续时间，单位s，取值范围1-20。
    preferredBufferDuration: 1,
    //播放策略true是hdr，false非hdr，默认非hdr。
    preferredHdr: false
  };
  private pendingSeekPosition: number = -1
  private playMusicIndex: number = 0
  // 是否被系统音频焦点抢占而中断（如来电、闹钟等）
  private isInterrupted: boolean = false;
  // 被中断前是否处于播放状态，用于焦点恢复时决定是否自动续播
  private wasPlayingBeforeInterrupt: boolean = false;

  private initPromise: Promise<void> | null = null;
  // 记录 initAudioPlayer 的初始化失败，供 waitForInitialization() 抛出，使 'init' 响应失败而非静默成功
  private initError: BusinessError | null = null;

  constructor() {
    // initAudioPlayer 为 async（内部 await createAVPlayer 等），构造函数无法 await，
    // 故将其 Promise 记录下来，供 waitForInitialization() 在 'init' 响应前等待，避免首次 load 时 avPlayer 未就绪
    this.initPromise = this.initAudioPlayer();
  }

  /**
   * 等待初始化完成（avPlayer/avMetadataExtractor/session 均已就绪）。
   * 供 AudioPlayer 在方法调用前 await，消除'构造即返回、avPlayer 尚为 null'的竞态。
   * */
  async waitForInitialization(): Promise<void> {
    if (this.initPromise) {
      await this.initPromise;
    }
    if (this.initError != null) {
      throw new Error(this.initError.message);
    }
  }

  setMediaAvPlayerStateChange(listener: onChangeMediaAvPlayerState) {
    this.mediaAvPlayerStateChangeListener = listener
  }

  private playCall: () => void = async () => {
    console.info(TAG, `on play , do play task`);
    if (this.isFirst) {
      await this.loadAsset(0);
    } else {
      this.play();
    }
  };
  private pauseCall: () => void = () => {
    console.info(TAG, `on pause , do pause task`);
    this.pause();
  };
  private playNextCall: () => void = () => {
    console.info(TAG, `on playNext , do playNext task`);
    this.playNextAuto();
  };
  private playPreviousCall: () => void = () => {
    console.info(TAG, `on playPrevious , do playPrevious task`);
    this.playPrevious();
  };
  /**
   * 异常监听
   * */
  private errorCall: (err: BusinessError) => void = (err: BusinessError) => {
    if (err.code == OPERATE_ERROR || err.code == AVPLAYER_STATE_ERROR) {
      // 未完成 prepare 时的操作/状态错误意味着加载失败，必须上报以复位 prepareResult，
      // 否则 Dart 端 load 的 Future 会一直等待导致悬挂；已 prepare 后多为操作时序类错误，仍予吞掉避免误报
      if (!this.isPrepared) {
        this.mediaAvPlayerStateChangeListener?.onErrorCallback(err);
      }
      console.error(TAG, `AvPlayer Avoid Error Reporting: ${err}`);
      return;
    }
    console.error(TAG, `Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
    this.mediaAvPlayerStateChangeListener?.onErrorCallback(err);
  };
  /**
   * 缓冲回调
   * */
  private bufferingUpdate: (infoType: media.BufferingInfoType, value: number) =>
  void = (infoType: media.BufferingInfoType, value: number) => {
    console.info(TAG, 'bufferingUpdate called,and infoType value is:' + infoType + ', value is :' + value);
    switch (infoType) {
      case media.BufferingInfoType.CACHED_DURATION:
        this.mediaAvPlayerStateChangeListener?.onUpdateBufferedPosition(value);
        break;
      case media.BufferingInfoType.BUFFERING_START:
        this.mediaAvPlayerStateChangeListener?.onStartBuffering();
        break;
      case media.BufferingInfoType.BUFFERING_PERCENT:
        if (value < 100) {
          this.mediaAvPlayerStateChangeListener?.onStartBuffering();
        } else if (this.seekModule != SeekMode.SEEK) {
          this.mediaAvPlayerStateChangeListener?.onEndBuffering();
        }
        break;
      case media.BufferingInfoType.BUFFERING_END:
        if (this.seekModule != SeekMode.SEEK) {
          this.mediaAvPlayerStateChangeListener?.onEndBuffering();
        }
        break;
    }
  }
  /**
   * 下一曲缓冲回调
   * */
  private bufferingUpdateNext: (infoType: media.BufferingInfoType, value: number) =>
  void = (infoType: media.BufferingInfoType, value: number) => {
    console.info(TAG, 'bufferingUpdateNext called,and infoType value is:' + infoType + ', value is :' + value);
  }
  /**
   * 监听资源播放当前时间，单位为毫秒（ms），用于刷新进度条当前位置，默认间隔100ms时间上报，因用户操作(seek)产生的时间变化会立刻上报
   * */
  private updateTimeCall: (updateTime: number) => void = (updateTime: number) => {
    if (this.volume != -1) {
      this.avPlayer?.setVolume(this.volume);
      this.volume = -1;
    }
    this.avPlayer?.setSpeed(this.speed);
    if (this.isClipping) {
      if (this.avPlayer && updateTime > 0 && this.getDuration() > 0 &&
        (this.songItem!.getEndUs() / 1000) < updateTime) {
        this.seek(this.playMode != LoopMode.SINGLE_CYCLE ? this.avPlayer.duration :
          (this.songItem!.getStartUs() / 1000));
      }
    }
  };
  /**
   * 进度条拖动回调,拖动松手后不会立刻回调,完成后回调
   * */
  private seekCall: (seekDoneTime: number) => void = async (seekDoneTime: number) => {
    this.mediaAvPlayerStateChangeListener?.completeSeek();
    this.seekModule = SeekMode.FINISH;
    if (this.state == AudioPlayerState.PREPARED || this.state == AudioPlayerState.PLAY ||
      this.state == AudioPlayerState.PAUSE || this.state == AudioPlayerState.COMPLETED) {
      this.playingState();
    }
    console.info(TAG, `AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
  };
  /**
   *订阅录制状态机AVRecorderState切换的事件，当 AVRecorderState状态机发生变化时，会通过订阅的回调方法通知用户。用户只能订阅一个状态机切换事件的回调方法，当用户重复订阅时，以最后一次订阅的回调接口为准
   * */
  private stateCall: (state: string) => Promise<void> = async (state: string) => {
    try {
    switch (state) {
      case 'idle':
        console.info(TAG, 'AVPlayer state idle called.');
        this.state = AudioPlayerState.IDLE;
        if (this.songList.length === 0) {
          break;
        }
        if (this.avPlayerNext == null) {
          this.offAVPlayerNextCallback();
          this.preMusicIndex = this.musicIndex + 1;
          let nextSong: MediaSource = this.songList[this.preMusicIndex];
          if (this.musicIndex == this.songList.length - 1) {
            if (this.playMode == LoopMode.LIST_LOOP) {
              this.preMusicIndex = 0;
              nextSong = this.songList[this.preMusicIndex];
            }
          }
          if (this.isRandom && this.shuffleOrder.length == this.songList.length) {
            let currentIndex = this.shuffleOrder.indexOf(this.musicIndex);
            if (currentIndex != -1) {
              if (currentIndex == this.shuffleOrder.length - 1) {
                this.preMusicIndex = this.shuffleOrder[0];
              } else {
                this.preMusicIndex = this.shuffleOrder[currentIndex+1];
              }
              nextSong = this.songList[this.preMusicIndex];
            }
          }
          if (nextSong) {
            media.createAVPlayer().then((value: media.AVPlayer) => {
              this.avPlayerNext = value;
              this.avPlayerNext.audioInterruptMode = audio.InterruptMode.SHARE_MODE;
              this.setAVPlayerNextCallback();
              let nextUrl = nextSong.getUri();
              if (nextUrl && this.avPlayerNext.state == 'idle') {
                this.loadUri(this.avPlayerNext, nextUrl);
              }
            }, (err: BusinessError) => {
              console.error(TAG, `createAVPlayer(next) failed, code is ${err.code}, message is ${err.message}`);
              this.mediaAvPlayerStateChangeListener?.onErrorCallback(err);
            });
          }
        }
        break;
      case 'initialized':
        console.info(TAG, 'AVPlayer state initialized called.');
        this.state = AudioPlayerState.INITIALIZED;
        if (this.avPlayer) {
          this.avPlayer.prepare().then(() => {
            console.info(TAG, 'AVPlayer prepare succeeded.');
          }, (err: BusinessError) => {
            console.error(TAG, `Invoke prepare failed, code is ${err.code}, message is ${err.message}`);
            this.mediaAvPlayerStateChangeListener?.onErrorCallback(err);
          });
        }
        break;
      case 'prepared':
        this.state = AudioPlayerState.PREPARED;
        this.isPrepared = true
        console.info(TAG, 'AVPlayer prepared .');
        if (this.initialPos != -1 && this.initialIndex != -1 && this.initialIndex == this.musicIndex) {
          this.seek(this.initialPos);
          this.initialPos = -1;
          this.initialIndex = -1;
          this.mediaAvPlayerStateChangeListener?.completeInitial();
          this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_READY);
          break;
        }
        if (this.isClipping) {
          this.avPlayer?.seek(this.songItem!.getStartUs() / 1000);
          this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_BUFFERING);
          break;
        }
        if (this.playMusicIndex == this.musicIndex) {
          this.playingState();
        } else {
          this.songItem = this.songList[this.musicIndex];
          let url = this.songItem?.getUri();
          if (url && this.avPlayer?.state == 'idle') {
            this.loadUri(this.avPlayer, url);
          }
        }
        try {
          this.avMetadata = await this.avMetadataExtractor?.fetchMetadata();
          this.setAVMetadata();
        } catch (err) {
          console.error(TAG, `fetchMetadata failed, ${JSON.stringify(err)}`);
        }
        break;
      case 'playing':
        console.info(TAG, 'AVPlayer state playing called.');
        this.pendingSeekPosition = -1
        this.isPlaying = true;
        this.state = AudioPlayerState.PLAY;
        this.mediaAvPlayerStateChangeListener?.onEndBuffering();
        // 通知播放真正开始，供 AudioPlayer 完成 Dart 端 play() 的 Future
        this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_PLAY);
        break;
      case 'paused':
        console.info(TAG, 'AVPlayer state paused called.');
        this.state = AudioPlayerState.PAUSE;
        break;
      case 'completed':
        console.info(TAG, 'AVPlayer state completed called.');
        this.state = AudioPlayerState.COMPLETED;
        if ((this.playMode == LoopMode.DEFAULT && this.musicIndex == this.songList.length - 1) ||
          this.songList.length == 0) {
          this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_ENDED);
        }
        this.playNextAuto();
        break;
      case 'stopped':
        console.info(TAG, 'AVPlayer state stopped called.');
        this.state = AudioPlayerState.STOP;
        break;
      case 'released':
        console.info(TAG, 'AVPlayer state released called.');
        this.state = AudioPlayerState.RELEASED;
        break;
      case 'error':
        console.error(TAG, 'AVPlayer state error called.');
        this.state = AudioPlayerState.ERROR;
        break;
      default:
        console.info(TAG, 'AVPlayer state unknown called.');
        this.state = AudioPlayerState.UNKNOWN;
        this.loadAsset(this.musicIndex)
        break;
    }
    } catch (err) {
      console.error(TAG, `stateCall failed, state is ${state}, error is ${JSON.stringify(err)}`);
      this.mediaAvPlayerStateChangeListener?.onErrorCallback(err as BusinessError);
    }
  };
  /**
   *订阅录制状态机AVRecorderState切换的事件，当 AVRecorderState状态机发生变化时，会通过订阅的回调方法通知用户。用户只能订阅一个状态机切换事件的回调方法，当用户重复订阅时，以最后一次订阅的回调接口为准
   * */
  private preStateCall: (state: string) => Promise<void> = async (state: string) => {
    switch (state) {
      case 'idle':
        console.info(TAG, 'avPlayerNext state idle called.');
        break;
      case 'initialized':
        console.info(TAG, 'avPlayerNext state initialized called.');
        this.avPlayerNext?.prepare().then(() => {
          console.info(TAG, 'avPlayerNext AVPlayer prepare succeeded.');
        }, (err: BusinessError) => {
          console.error(TAG, `avPlayerNext Invoke prepare failed, code is ${err.code}, message is ${err.message}`);
          this.mediaAvPlayerStateChangeListener?.onErrorCallback(err);
        });
        break;
      case 'prepared':
        if (this.isPreBuffering) {
          console.info(TAG, 'avPlayerNext state isPreBuffering ');
          this.isPreBuffering = false;
          this.playingState();
        }
        console.info(TAG, 'avPlayerNext state prepared ');
        break;
      case 'playing':
        console.info(TAG, 'avPlayerNext state playing called.');
        break;
      case 'paused':
        console.info(TAG, 'avPlayerNext state paused called.');
        break;
      case 'completed':
        console.info(TAG, 'avPlayerNext state completed called.');
        break;
      case 'stopped':
        console.info(TAG, 'avPlayerNext state stopped called.');
        break;
      case 'released':
        console.info(TAG, 'avPlayerNext state released called.');
        this.avPlayerNext = null;
        break;
      default:
        console.info(TAG, 'avPlayerNext state unknown called.');
        break;
    }
  };

  playingState() {
    if (this.isPlaying) {
      this.avPlayer?.play().then(() => {
        console.info(TAG, 'AVPlayer play succeeded.');
        this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_READY);
      }, (err: BusinessError) => {
        console.error(TAG, `Invoke play failed, code is ${err.code}, message is ${err.message}`);
      });
    } else if (this.avPlayer?.state == 'prepared' || this.avPlayer?.state == 'paused') {
      this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_READY);
    }
  }

  setAVPlayerNextCallback() {
    this.avPlayerNext?.on('stateChange', this.preStateCall);
    this.avPlayerNext?.on('bufferingUpdate', this.bufferingUpdateNext);
  }


  offAVPlayerNextCallback() {
    this.avPlayerNext?.off('stateChange', this.preStateCall);
    this.avPlayerNext?.off('bufferingUpdate', this.bufferingUpdateNext);
  }

  /**
   * 注销会话控制回调，避免 dispose 后仍被系统控制事件触发。
   */
  offSessionCallback() {
    this.session?.off('play', this.playCall);
    this.session?.off('pause', this.pauseCall);
    this.session?.off('playNext', this.playNextCall);
    this.session?.off('playPrevious', this.playPreviousCall);
  }


  setListenerForMesFromController() {
    if (!this.session) {
      return;
    }
    this.session.on('play', this.playCall);
    this.session.on('pause', this.pauseCall);
    this.session.on('playNext', this.playNextCall);
    this.session.on('playPrevious', this.playPreviousCall);
  }

  /**
   * 音频中断回调：来电/闹钟等抢占音频焦点时，系统会通过该事件通知应用。
   * AVPlayer 默认以 SHARE_MODE 注册音频焦点：
   * - INTERRUPT_HINT_PAUSE/STOP：焦点被抢占（如来电、闹钟），播放被暂停/停止，需同步 playing=false 给 Dart 端；
   * - INTERRUPT_HINT_RESUME：焦点恢复，可继续播放，需同步 playing=true 给 Dart 端；
   * - INTERRUPT_HINT_DUCK/UNDUCK：焦点被低优先级应用共享，仅降低音量，不改变播放状态。
   */
  private audioInterruptCall: (event: audio.InterruptEvent) => void = (event: audio.InterruptEvent) => {
    console.info(TAG, `on audioInterrupt, eventType=${event.eventType}, forceType=${event.forceType}, hintType=${event.hintType}`);
    switch (event.hintType) {
      case audio.InterruptHint.INTERRUPT_HINT_PAUSE:
      case audio.InterruptHint.INTERRUPT_HINT_STOP:
        this.isInterrupted = true;
        // 记录被中断前是否正在播放，避免焦点恢复时覆盖用户手动暂停
        this.wasPlayingBeforeInterrupt = this.isPlaying;
        this.isPlaying = false;
        this.mediaAvPlayerStateChangeListener?.onAudioFocusChanged(false);
        break;
      case audio.InterruptHint.INTERRUPT_HINT_RESUME:
        if (this.isInterrupted) {
          this.isInterrupted = false;
          // 焦点恢复时仅恢复播放，若用户此前已手动暂停则不自动恢复
          if (this.wasPlayingBeforeInterrupt) {
            this.isPlaying = true;
            this.playingState();
            this.mediaAvPlayerStateChangeListener?.onAudioFocusChanged(true);
          }
          this.wasPlayingBeforeInterrupt = false;
        }
        break;
      case audio.InterruptHint.INTERRUPT_HINT_DUCK:
      case audio.InterruptHint.INTERRUPT_HINT_UNDUCK:
        // 低优先级共享焦点：仅音量变化，播放状态不变
        break;
      default:
        break;
    }
  };

  /**
   * 为服务设置回调监听
   * */
  private setAVPlayerCallback() {
    if (!this.avPlayer) {
      return;
    }
    this.avPlayer.on('seekDone', this.seekCall);

    this.avPlayer.on('error', this.errorCall);

    this.avPlayer.on('timeUpdate', this.updateTimeCall);

    this.avPlayer.on('bufferingUpdate', this.bufferingUpdate);

    this.avPlayer.on('stateChange', this.stateCall);

    this.avPlayer.on('audioInterrupt', this.audioInterruptCall);

  }

  /**
   * 为服务注销回调监听
   * */
  private offAVPlayerCallback() {
    if (!this.avPlayer) {
      return;
    }
    this.avPlayer.off('seekDone', this.seekCall);

    this.avPlayer.off('error', this.errorCall);

    this.avPlayer.off('timeUpdate', this.updateTimeCall);

    this.avPlayer.off('bufferingUpdate', this.bufferingUpdate);

    this.avPlayer.off('stateChange', this.stateCall);

    this.avPlayer.off('audioInterrupt', this.audioInterruptCall);

  }

  /**
   * Play previous music.
   */
  public async playPrevious() {


    switch (this.playMode) {
      case LoopMode.LIST_LOOP:
      case LoopMode.DEFAULT:
        if (this.isRandom) {
          this.playRandom();
          break;
        }
        if (this.musicIndex === 0) {
          this.updateMusicIndex(this.songList.length - 1);
        } else {
          this.updateMusicIndex(this.musicIndex - 1);
        }
        this.loadAsset(this.musicIndex);
        break;
      default:
        break;
    }
  }

  private updateMusicIndex(musicIndex: number) {
    this.mediaAvPlayerStateChangeListener?.onUpdateCurrentIndex(musicIndex)
    if (this.musicIndex !== musicIndex) {
      this.musicIndex = musicIndex;
    }
    if (this.session !== undefined) {
      this.setAVMetadata();
    }
  }

  async setAVMetadata() {
    let id = this.musicIndex;
    try {
      let metadata: avSession.AVMetadata = {
        assetId: `${id}`,
        title: this.avMetadata?.title ?? '未知',
        artist: this.avMetadata?.artist ?? '未知',
        mediaImage: this.avMetadata?.albumArtist,
        duration: this.getDuration()
      };
      if (this.session) {
        this.session.setAVMetadata(metadata).then(() => {
          console.info(TAG, 'SetAVMetadata successfully');
        }).catch((err: BusinessError) => {
          console.error(TAG, `SetAVMetadata BusinessError: code: ${err.code}, message: ${err.message}`);
        });
      }
    } catch (error) {
      console.error(TAG,
        `SetAVMetadata try: code: ${(error as BusinessError).code},message: ${(error as BusinessError).message}`);
    }
  }

  public getDuration() {
    if (this.isPrepared && this.avPlayer) {
      if (this.isClipping && this.songItem) {
        let duration = this.songItem.getEndUs() - this.songItem.getStartUs();
        return duration / 1000;
      }
      return this.avPlayer.duration;
    }
    return 0;
  }

  public setLoopMode(loopMode: number) {
    this.playMode = loopMode;
  }

  public setShuffleMode(isShuffle: boolean) {
    this.isRandom = isShuffle;
  }

  public setVolume(volume: number) {
    this.volume = volume
    this.avPlayer?.setVolume(volume);
  }

  public setSpeed(speed: number) {
    if (speed > 0 && speed <= 0.125) {
      //x0.125
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_125_X;
    } else if (speed > 0.125 && speed <= 0.4) {
      //x0.25
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_25_X;
    } else if (speed > 0.4 && speed <= 0.6) {
      //x0.5
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_50_X;
    } else if (speed > 0.6 && speed <= 0.8) {
      //x0.75
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
    } else if (speed > 0.8 && speed <= 1.1) {
      //x1
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
    } else if (speed > 1.1 && speed <= 1.4) {
      //x1.25
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
    } else if (speed > 1.4 && speed <= 1.6) {
      //x1.5
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_50_X;
    } else if (speed > 1.6 && speed <= 1.8) {
      //x1.75
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X;
    } else if (speed > 1.8 && speed <= 2.0) {
      //x2.0
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
    } else if (speed > 2.0) {
      //由于2.0~3.0中间没有枚举速率,并且速率最大值为3.0,,所以大于2.0的速率都将映射到3.0x速度
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_3_00_X;
    }
    this.avPlayer?.setSpeed(this.speed);
  }

  /**
   * 初始化音频播放器
   * */
  async initAudioPlayer() {
    try {
      if (!this.avPlayer) {
        this.avPlayer = await media.createAVPlayer();
      }
      this.avPlayer.audioInterruptMode = audio.InterruptMode.SHARE_MODE;
      this.avMetadataExtractor = await media.createAVMetadataExtractor();
      this.setAVPlayerCallback();
      await this.createSession();
    } catch (err) {
      console.error(TAG, `initAudioPlayer failed: ${JSON.stringify(err)}`);
      this.initError = err as BusinessError;
      this.mediaAvPlayerStateChangeListener?.onErrorCallback(err as BusinessError);
    }
  }

  async createSession() {
    if (!this.context) {
      return;
    }
    try {
      this.session = await avSession.createAVSession(this.context, 'SESSION_NAME', 'audio');
      this.session.activate();
      this.setAVMetadata();
      let wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: this.context.abilityInfo.bundleName,
            abilityName: this.context.abilityInfo.name
          }
        ],
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      }
      let agent = await wantAgent.getWantAgent(wantAgentInfo);
      if (this.session) {
        this.session.setLaunchAbility(agent);
      }
      this.mediaAvPlayerStateChangeListener?.setAudioSessionId(parseInt(this.session.sessionId))
      this.setListenerForMesFromController();
    } catch (err) {
      console.error(TAG, `createSession failed: ${JSON.stringify(err)}`);
      this.mediaAvPlayerStateChangeListener?.onErrorCallback(err as BusinessError);
    }
  }

  /**
   * Play music.
   */
  public async play(result?: MethodResult) {
    this.isPlaying = true;
    // 用户主动播放，重置中断状态，避免焦点恢复事件误触发自动续播
    this.isInterrupted = false;
    this.wasPlayingBeforeInterrupt = false;
    if (!this.isPrepared) {
      this.start(0);
    } else if (this.avPlayer) {
      this.avPlayer.play().then(() => {
        this.updateIsPlay(true);
        this.state = AudioPlayerState.PLAY;
        result?.success(new Map<String, Object>());
      }).catch((e: BusinessError) => {
        result?.error(e.code.toString(), e.message, e.data);
        console.error(TAG, 'play::error:' + e.message);
      })
    }
  }

  /**
   * Pause music.
   */
  public pause(result?: MethodResult) {
    if (this.isPlaying && this.avPlayer) {
      this.isPlaying = false;
      // 用户主动暂停，重置中断状态，避免焦点恢复事件误触发自动续播
      this.isInterrupted = false;
      this.wasPlayingBeforeInterrupt = false;
      this.avPlayer.pause().then(() => {
        this.state = AudioPlayerState.PAUSE;
        this.updateIsPlay(false);
        result?.success(new Map<String, Object>());
      }).catch((e: BusinessError) => {
        result?.error(e.code.toString(), e.message, e.data)
        console.error(TAG, 'pause::error' + e.message);
      });
    } else {
      // 非播放状态或播放器未就绪时也需回执，避免 Dart 端 Future 一直等待导致悬挂
      result?.success(new Map<String, Object>());
    }
  }

  /**
   * Play next music.
   *
   * @param isFromControl
   */
  public async playNextAuto() {


    switch (this.playMode) {
      case LoopMode.SINGLE_CYCLE:
        if (this.avPlayer) {
          this.avPlayer.loop = true;
          this.loadAsset(this.musicIndex);
        }
        break;
      case LoopMode.LIST_LOOP:
      case LoopMode.DEFAULT:
        if (this.avPlayer) {
          this.avPlayer.loop = false;
        }
        if (this.isRandom) {
          this.playRandom();
        } else {
          this.playNext();
        }
        break;
      default:
        break;
    }
  }

  /**
   * Play music by index.
   *
   * @param musicIndex
   */
  async loadAsset(musicIndex: number) {
    if (this.seekModule == SeekMode.SEEK) {
      this.seekModule = SeekMode.UNKNOWN;
    }
    if (this.songList.length == 0) {
      console.error(TAG, `loadAsset: empty songList, cannot load index ${musicIndex}`);
      return;
    }
    // 越界时收敛到合法区间并继续加载，避免原逻辑'纠正后 return'导致实际不加载任何曲子
    if (musicIndex < 0) {
      musicIndex = 0;
    } else if (musicIndex >= this.songList.length) {
      musicIndex = this.songList.length - 1;
    }
    this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_BUFFERING);
    this.mediaAvPlayerStateChangeListener?.onUpdateBufferedPosition(0);
    this.songItem = this.songList[musicIndex];
    this.isClipping = this.songItem.type == 'clipping';
    this.updateMusicIndex(musicIndex);
    if (this.avPlayerNext && this.preMusicIndex == musicIndex && !this.isFirst) {
      this.offAVPlayerCallback();
      // 切换前先注销 avPlayerNext 上的预加载回调，避免其升级为 avPlayer 后与 setAVPlayerCallback() 双重注册
      this.offAVPlayerNextCallback();
      this.avPlayer?.release()?.catch((err: BusinessError) => {
        console.error(TAG, `release avPlayer failed, code is ${err.code}, message is ${err.message}`);
      });
      this.avPlayer = this.avPlayerNext;
      this.setAVPlayerCallback();
      if (this.avPlayerNext.state == 'prepared') {
        this.playingState();
      } else {
        this.isPreBuffering = true;
      }
      this.avPlayerNext = null;
    } else {
      if (this.avPlayer) {
        this.offAVPlayerNextCallback()
        this.avPlayerNext?.release()?.catch((err: BusinessError) => {
          console.error(TAG, `release avPlayerNext failed, code is ${err.code}, message is ${err.message}`);
        });
        this.avPlayerNext = null;
        if (this.isFirst) {
          this.isFirst = false;
        } else {
          await this.avPlayer.reset();
          this.playMusicIndex = musicIndex;
        }
        let url = this.songItem?.getUri();
        if (url && this.avPlayer.state == 'idle') {
          this.loadUri(this.avPlayer, url);
        }
      }
    }
  }

  dispose() {
    // 注销 AVPlayer 回调，避免释放后仍被事件触发
    this.offAVPlayerCallback();
    this.offAVPlayerNextCallback();
    // 注销会话控制回调并关闭会话
    this.offSessionCallback();
    if (this.session) {
      let sess: avSession.AVSession | undefined = this.session;
      this.session = undefined;
      sess.deactivate().then(() => {
        if (sess) {
          sess.destroy().catch((err: BusinessError) => {
            console.error(TAG, `destroy session failed, code is ${err.code}, message is ${err.message}`);
          });
        }
      }).catch((err: BusinessError) => {
        console.error(TAG, `deactivate session failed, code is ${err.code}, message is ${err.message}`);
        // deactivate 失败时仍尝试销毁会话，避免 AVSession 泄漏
        if (sess) {
          sess.destroy().catch((err2: BusinessError) => {
            console.error(TAG, `destroy session failed after deactivate error, code is ${err2.code}, message is ${err2.message}`);
          });
        }
      });
    }
    // 关闭所有通过 fileIo.openSync 打开的文件描述符，避免 fd 泄漏
    this.fdMap.forEach((fd: number) => {
      try {
        fileIo.closeSync(fd);
      } catch (err) {
        console.error(TAG, `close fd ${fd} failed, ${JSON.stringify(err)}`);
      }
    });
    this.fdMap.clear();
    this.avPlayer?.release()?.catch((err: BusinessError) => {
      console.error(TAG, `release avPlayer failed, code is ${err.code}, message is ${err.message}`);
    });
    this.avPlayerNext?.release()?.catch((err: BusinessError) => {
      console.error(TAG, `release avPlayerNext failed, code is ${err.code}, message is ${err.message}`);
    });
    this.avMetadataExtractor?.release();
    this.avMetadataExtractor = null;
    this.avPlayerNext = null;
    this.avPlayer = null;
    // 清空播放列表相关数据
    this.songList = [];
    this.songItem = null;
    this.shuffleOrder = [];
    this.preMusicIndex = 0;
    this.musicIndex = 0;
    this.playMusicIndex = 0;
    this.isPlaying = false;
    this.isPrepared = false;
    this.isFirst = true;
    this.mediaAvPlayerStateChangeListener = undefined;
  }

  private playNext() {
    if (this.musicIndex === this.songList.length - 1) {
      if (this.playMode == LoopMode.LIST_LOOP) {
        this.loadAsset(0);
      }
    } else {
      this.loadAsset(this.musicIndex + 1);
    }
  }

  private playRandom() {
    // 歌曲列表只有1首时跳过随机播放逻辑
    if (this.songList.length <= 1) {
      return;
    }
    if (this.shuffleOrder.length == 0) {
      // 本地生成洗牌序列，避免 Math.random() 无记忆导致重复
      this.shuffleOrder = this.generateShuffleOrder();
    }
    let orderIndex = this.shuffleOrder.indexOf(this.musicIndex);
    let num = orderIndex == this.shuffleOrder.length - 1 ? 0 : orderIndex + 1;
    this.updateMusicIndex(this.shuffleOrder[num]);
    this.loadAsset(this.shuffleOrder[num]);
  }

  /**
   * 生成 Fisher-Yates 洗牌序列，确保一轮内每首歌只播放一次，避免 Math.random() 无记忆导致的重复播放问题。
   * @returns 打乱后的歌曲索引数组
   */
  private generateShuffleOrder(): number[] {
    // 初始化顺序索引 [0, 1, 2, ..., N-1]
    let order: number[] = [];
    for (let i = 0; i < this.songList.length; i++) {
      order.push(i);
    }
    // Fisher-Yates 洗牌算法：从末尾向前遍历，随机交换当前位置与之前某个位置的元素
    for (let i = order.length - 1; i > 0; i--) {
      let j = Math.floor(Math.random() * (i + 1));
      let temp = order[i];
      order[i] = order[j];
      order[j] = temp;
    }
    return order;
  }

  /**
   * Seek play music.
   *
   * @param ms.
   */
  public async seek(ms: number, index?: number | null) {

    this.mediaAvPlayerStateChangeListener?.onStartBuffering();
    if (ms == this.avPlayer?.duration) {
      if (this.isRandom) {
        this.playRandom();
      } else if (this.playMode == LoopMode.LIST_LOOP) {
        this.playNext()
      } else {
        this.avPlayer.seek(this.avPlayer?.duration);
      }
      // 必须回执 seek 结果，否则 Dart 端 seek() 的 Future 会一直等待
      this.mediaAvPlayerStateChangeListener?.completeSeek();
      return;
    }

    let seekMode = this.getCurrentTime() < ms ? 0 : 1;
    if (this.isClipping) {
      ms = this.songItem!.getStartUs() / 1000 + ms;
    }
    let realTime = ms <= 0 ? 0 : ms;
    if (index != null && index != this.musicIndex) {
      this.avPlayer?.reset();
      this.loadAsset(index);
    } else {
      if ((this.state == AudioPlayerState.PREPARED || this.state == AudioPlayerState.PLAY ||
        this.state == AudioPlayerState.COMPLETED || this.state == AudioPlayerState.PAUSE) && this.avPlayer) {
        this.seekModule = SeekMode.SEEK;
        this.avPlayer.seek(realTime, seekMode);
      }
    }
  }

  private async loadUri(avPlayer: media.AVPlayer, uri: string) {
    if (uri?.startsWith('http')) {
      // 仅当音源显式携带请求头时才下发，避免发送无意义的占位符 User-Agent
      let headers: Record<string, string> = this.songItem?.getHeader() ?? {};
      let mediaSource: media.MediaSource = media.createMediaSourceWithUrl(uri, headers);
      avPlayer.setMediaSource(mediaSource, this.playStrategy);
    } else if (uri?.startsWith('file')) {
      if (this.context) {
        const dartFilePrefix = 'file:///';
        if (uri.startsWith(dartFilePrefix)) {
          uri = uri.slice(dartFilePrefix.length);
        }
        // 同一 uri 重复打开时先关闭旧 fd，避免文件描述符泄漏
        let existedFd: number | undefined = this.fdMap.get(uri);
        if (existedFd != undefined) {
          try {
            fileIo.closeSync(existedFd);
          } catch (err) {
            console.error(TAG, `close existed fd ${existedFd} failed, ${JSON.stringify(err)}`);
          }
        }
        let fd: number = -1;
        let fileSize: number = -1;
        try {
          fd = fileIo.openSync(uri).fd;
          fileSize = fileIo.statSync(uri).size;
        } catch (err) {
          // 文件不存在或权限不足等异常时清理已打开的 fd 并向上传播，避免应用崩溃
          if (fd != -1) {
            try {
              fileIo.closeSync(fd);
            } catch (closeErr) {
              console.error(TAG, `close fd ${fd} failed, ${JSON.stringify(closeErr)}`);
            }
          }
          console.error(TAG, `open/stat file failed, uri ${uri}, ${JSON.stringify(err)}`);
          this.mediaAvPlayerStateChangeListener?.onErrorCallback(err as BusinessError);
          return;
        }
        this.fdMap.set(uri, fd);
        let src: media.AVDataSrcDescriptor = {
          fileSize: fileSize,
          callback: (buf: ArrayBuffer, length: number, pos: number | undefined) => {
            if (buf == undefined || length == undefined || pos == undefined) {
              return -1;
            }
            try {
              let num = fileIo.readSync(fd, buf, { offset: pos, length: length });
              if (num > 0 && (fileSize >= pos)) {
                return num;
              }
              return -1;
            } catch (err) {
              console.error(TAG, `read file failed, uri ${uri}, ${JSON.stringify(err)}`);
              return -1;
            }
          }
        }
        src.fileSize = fileSize;
        avPlayer.dataSrc = src;
        if (this.avMetadataExtractor) {
          this.avMetadataExtractor.dataSrc = src;
        }
      }
    } else {
      if (this.context) {
        // url 在 AVPlayer 接口中为 string | undefined，此处走 rawfile 分支时做兜底
        let url: string = avPlayer.url ?? '';
        let fileDescriptor = await getContext(this).resourceManager.getRawFd(url)
          .catch((error: BusinessError) => {
            console.error(`resourceManager error code ${error.code} message ${error.message}`);
            this.mediaAvPlayerStateChangeListener?.onErrorCallback(error);
            return null;
          });
        if (fileDescriptor) {
          // rawfile fd 加入 fdMap 追踪，重复打开时先关闭旧 fd，避免文件描述符泄漏
          let fdKey: string = 'rawfile:' + url;
          let existedFd: number | undefined = this.fdMap.get(fdKey);
          if (existedFd != undefined) {
            try {
              fileIo.closeSync(existedFd);
            } catch (err) {
              console.error(TAG, `close existed rawfile fd ${existedFd} failed, ${JSON.stringify(err)}`);
            }
          }
          this.fdMap.set(fdKey, fileDescriptor.fd);
          let avFileDescriptor: media.AVFileDescriptor =
            { fd: fileDescriptor.fd, offset: fileDescriptor.offset, length: fileDescriptor.length };
          if (this.avMetadataExtractor) {
            this.avMetadataExtractor.fdSrc = avFileDescriptor;
          }
          avPlayer.fdSrc = avFileDescriptor;
        }
      }
    }
  }

  public addPublicMediaSources(index: number, mediaSources: Array<MediaSource>) {
    if (mediaSources.length === 0) {
      return;
    }
    let insertIndex = index >= 0 ? index : this.songList.length;
    if (insertIndex > this.songList.length) {
      insertIndex = this.songList.length;
    }
    const wasEmpty = this.songList.length === 0;
    if (!wasEmpty && insertIndex <= this.musicIndex) {
      this.updateMusicIndex(this.musicIndex + mediaSources.length);
    }
    const before = this.songList.slice(0, insertIndex);
    const after = this.songList.slice(insertIndex);
    this.songList = before.concat(mediaSources, after);
    if (this.avPlayerNext != null && !wasEmpty) {
      this.offAVPlayerNextCallback();
      this.avPlayerNext.release().catch((err: BusinessError) => {
        console.error(TAG, `release avPlayerNext failed, code is ${err.code}, message is ${err.message}`);
      });
      this.avPlayerNext = null;
      this.preMusicIndex = -1;
    }
    if (wasEmpty && this.avPlayer?.state == 'idle') {
      this.isFirst = true;
      this.loadAsset(0);
    }
  }

  public async removeMediaSourceRange(startIndex: number, endIndex: number) {
    if (startIndex < 0 || endIndex > this.songList.length || startIndex >= endIndex) {
      const message =
        `Invalid removeMediaSourceRange parameters: startIndex=${startIndex}, endIndex=${endIndex}, listLength=${this.songList.length}`;
      Log.e(TAG, message);
      throw new Error(message);
    }
    const deleteCount = endIndex - startIndex;
    this.songList.splice(startIndex, deleteCount);
    this.adjustPreMusicIndexAfterRemove(startIndex, endIndex);
    if (this.songList.length > 0) {
      if (this.musicIndex >= startIndex && this.musicIndex < endIndex) {
        await this.loadAsset(Math.min(startIndex, this.songList.length - 1));
      }
      this.updateCurrentIndex();
    } else {
      this.invalidateAvPlayerNext();
      this.isPlaying = false;
      this.isPrepared = false;
      this.songItem = null;
      this.musicIndex = 0;
      this.mediaAvPlayerStateChangeListener?.onUpdateCurrentIndex(0);
      this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_ENDED);
    }
  }

  public moveMediaSource(currentIndex: number, newIndex: number) {
    let moveItem = this.songList.splice(currentIndex, 1);
    this.songList.splice(newIndex, 0, moveItem[0]);
    this.updateCurrentIndex();
  }

  private updateCurrentIndex() {
    let index = this.songList.indexOf(this.songItem!);
    if (index != -1) {
      this.musicIndex = index;
      this.mediaAvPlayerStateChangeListener?.onUpdateCurrentIndex(index);
    }
  }

  private invalidateAvPlayerNext(): void {
    if (this.avPlayerNext != null) {
      this.offAVPlayerNextCallback();
      this.avPlayerNext.release().catch((err: BusinessError) => {
        console.error(TAG, `release avPlayerNext failed, code is ${err.code}, message is ${err.message}`);
      });
      this.avPlayerNext = null;
    }
    this.preMusicIndex = -1;
  }

  /**
   * splice 删除后同步预缓冲索引：删除范围内则释放 avPlayerNext，否则按删除数量前移索引。
   */
  private adjustPreMusicIndexAfterRemove(startIndex: number, endIndex: number): void {
    if (this.preMusicIndex < 0) {
      return;
    }
    if (this.preMusicIndex >= startIndex && this.preMusicIndex < endIndex) {
      this.invalidateAvPlayerNext();
    } else if (this.preMusicIndex >= endIndex) {
      this.preMusicIndex -= (endIndex - startIndex);
    }
  }

  public setShuffleOrder(shuffleOrder: number[]) {
    this.shuffleOrder = shuffleOrder;
  }

  private getChildList(playList: MediaSource[]): MediaSource[] {
    if (playList.length == 1 && playList[0].getType() === 'concatenating') {
      return this.getChildList(playList[0].getChildMediaSource());
    }
    return playList;
  }

  public async load(mediaSource: MediaSource, currentIndex: number, seekPosition: number = 0) {
    this.initialPos = seekPosition ?? -1;
    if (this.initialPos != -1) {
      this.initialIndex = currentIndex
    }
    if (this.playMode != LoopMode.DEFAULT) {
      mediaSource.setMusicPlayMode(this.playMode);
    }
    let mSource: media.MediaSource;
    let mediaType = mediaSource.getType();
    if (mediaType == 'concatenating') {
      this.songList = this.getChildList(mediaSource.getChildMediaSource())
      this.playMode = mediaSource.getMusicPlayMode();
      this.setShuffleOrder(mediaSource.shuffleOrder);
      if (this.songList.length == 0) {
        console.info(TAG, 'load empty playlist, notify ended.');
        this.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.STATE_ENDED);
        return;
      }
      this.loadAsset(currentIndex);
    } else {
      this.songList = [mediaSource];
      if (mediaType == 'clipping') {
        this.loadAsset(currentIndex);
      } else if (mediaSource.getHeader()) {
        mSource = media.createMediaSourceWithUrl(mediaSource.getUri(), mediaSource.getHeader());
        await this.avPlayer?.setMediaSource(mSource, this.playStrategy);
        await this.avPlayer?.prepare();
      } else {
        this.loadAsset(currentIndex)
      }
    }
  }

  public stop() {
    this.avPlayer?.stop();
  }

  private start(seekMs?: number) {
    if (this.avPlayer) {
      this.avPlayer.prepare().then(() => {
      }).catch((error: BusinessError) => {
        console.error(TAG, `start error ${JSON.stringify(error)}`);
        this.state = AudioPlayerState.ERROR;
        this.updateIsPlay(false);
        this.isPrepared = false;
      });
    }
  }

  private updateIsPlay(display: boolean) {
    this.setPlayState({
      state: display ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      position: {
        elapsedTime: this.getCurrentTime(),
        updateTime: new Date().getTime()
      }
    });
  }

  public getCurrentTime() {
    if (this.isPrepared && this.avPlayer) {
      if (this.isClipping) {
        return this.avPlayer.currentTime - (this.songItem!.getStartUs() / 1000);
      }
      if (this.initialPos != -1 && this.initialPos != 0) {
        this.pendingSeekPosition = this.initialPos
      }
      if (this.pendingSeekPosition != -1) {
        return this.pendingSeekPosition
      } else {
        return this.avPlayer.currentTime;
      }

    }
    return 0;
  }

  private setPlayState(playbackState: avSession.AVPlaybackState) {
    if (this.session) {
      this.session.setAVPlaybackState(playbackState, (err: BusinessError) => {
        if (err) {
          console.error(TAG, `SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
        } else {
          console.info(TAG, 'SetAVPlaybackState successfully');
        }
      });
    }
  }
}
