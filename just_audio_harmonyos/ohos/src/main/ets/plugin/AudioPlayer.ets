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
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR AInvoke avPlayer NY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * */

import { MethodCallHandler, MethodCall, MethodChannel, MethodResult, Any, Log } from '@ohos/flutter_ohos';
import { BetterEventChannel } from './BetterEventChannel';
import { media } from '@kit.MediaKit';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { BinaryMessenger } from '@ohos/flutter_ohos';
import MediaSource from './MediaSource';
import { MediaAvPlayer, PlaybackState, onChangeMediaAvPlayerState, AudioPlayerState } from './MediaAvPlayer';

enum ProcessingState {
  none,
  loading,
  buffering,
  ready,
  completed
}

const TAG = 'AudioPlayer';

export class AudioPlayer implements MethodCallHandler, onChangeMediaAvPlayerState {
  private pendingPlaybackEvent: Map<String, Object> | null = null;
  private methodChannel: MethodChannel | null = null;
  private eventChannel: BetterEventChannel | null = null;
  private dataEventChannel: BetterEventChannel | null = null;
  private bufferedPosition: number = 0;
  public static TIME_UNSET: number = -9223372036854775807;
  public static AUDIO_SESSION_ID_UNSET: number = 0;
  // 连接被中止时使用的错误码，Dart 端会将 10000000 识别为 PlayerInterruptedException
  private static readonly ERROR_ABORT: number = 10000000;
  private initialPos: number | null = null;
  private initialIndex: number | null = null;
  private prepareResult: MethodResult | null = null;
  private playResult: MethodResult | null = null;
  private seekResult: MethodResult | null = null;
  private player: MediaAvPlayer | null = null;
  private mediaSource: MediaSource | null = null;
  private mediaSources: Map<String, MediaSource | undefined> = new Map<String, MediaSource | undefined>();
  private currentIndex: number = 0;
  private audioSessionId: number | null = null;
  private processingState: ProcessingState = ProcessingState.none;
  private pendingSpeed: number | null = null;
  private seekPos: number | null = null;
  private updatePosition: number = 0;
  private updateTime: number = 0;
  // 最近一次错误的错误码与信息，供 createPlaybackEvent 透传给 Dart 端 PlaybackEvent
  private errorCode: string | null = null;
  private errorMessage: string | null = null;

  public constructor(messenger: BinaryMessenger, id: string) {
    this.player = new MediaAvPlayer();
    this.player.setMediaAvPlayerStateChange(this);
    this.methodChannel = new MethodChannel(messenger, 'com.ryanheise.just_audio.methods.' + id);
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new BetterEventChannel(messenger, 'com.ryanheise.just_audio.events.' + id);
    this.dataEventChannel = new BetterEventChannel(messenger, 'com.ryanheise.just_audio.data.' + id);
    this.processingState = ProcessingState.none;
  }

  // 等待底层 MediaAvPlayer 初始化完成，供 MainMethodCallHandler 在 'init' 响应前 await，
  // 消除"构造即返回、avPlayer 尚为 null"时立即 load 的竞态
  async waitForInitialization(): Promise<void> {
    await this.player?.waitForInitialization();
  }

  onErrorCallback(err: BusinessError<void>): void {
    // 优先上报错误码（如无网络时的 5400103/5400104），供 Dart 端 load 结束 loading 并抛错
    this.sendError(err.code != undefined ? err.code.toString() : err.name, err.message)
  }

  onAudioFocusChanged(isPlaying: boolean): void {
    this.broadcastPlayerData(isPlaying);
  }

  onUpdateCurrentIndex(updateIndex: number): void {
    this.currentIndex = updateIndex;
    this.broadcastImmediatePlaybackEvent();
  }

  broadcastImmediatePlaybackEvent() {
    this.enqueuePlaybackEvent();
    this.broadcastPendingPlaybackEvent();
  }

  completeSeek() {
    this.seekPos = null;
    this.seekResult?.success(new Map<String, Object>());
    this.seekResult = null;
  }

  setAudioSessionId(audioSessionId: number) {
    if (audioSessionId == AudioPlayer.AUDIO_SESSION_ID_UNSET) {
      this.audioSessionId = null;
    } else {
      this.audioSessionId = audioSessionId;
    }
    this.enqueuePlaybackEvent();
  }

  onAudioSessionIdChanged(audioSessionId: number) {
    this.setAudioSessionId(audioSessionId);
    this.broadcastPendingPlaybackEvent();
  }

  onPlaybackStateChanged(state: PlaybackState) {
    switch (state) {
      case PlaybackState.STATE_READY:
        this.onUpdatePosition();
        this.processingState = ProcessingState.ready;
        this.broadcastImmediatePlaybackEvent();
        if (this.pendingSpeed != null) {
          this.setSpeed(this.pendingSpeed);
          this.pendingSpeed = null;
        }
        if (this.prepareResult != null) {
          let response: Map<String, Object> = new Map<String, Object>();
          response.set('duration', this.getDuration() == AudioPlayer.TIME_UNSET ? -1 : (1000 * this.getDuration()));
          this.prepareResult.success(response);
          this.prepareResult = null;
        }
        if (this.seekResult != null) {
          this.completeSeek();
        }
        break;
      case PlaybackState.STATE_BUFFERING:
        this.updatePositionIfChanged()
        if (this.processingState != ProcessingState.buffering && this.processingState != ProcessingState.loading) {
          this.processingState = ProcessingState.buffering;
          this.broadcastImmediatePlaybackEvent();
        }
        break;
      case PlaybackState.STATE_PLAY:
        this.onUpdatePosition();
        if (this.playResult != null) {
          this.playResult.success(new Map<String, Object>());
          this.playResult = null;
        }
        break;
      case PlaybackState.STATE_ENDED:
        if (this.processingState != ProcessingState.completed) {
          this.onUpdatePosition(); // 保持末尾位置，不归零
          this.processingState = ProcessingState.completed;
          this.broadcastImmediatePlaybackEvent();
        }
        if (this.prepareResult != null) {
          let response: Map<String, Object> = new Map<String, Object>();
          this.prepareResult.success(response);
          this.prepareResult = null;
        }
        if (this.playResult != null) {
          this.playResult.success(new Map<String, Object>());
          this.playResult = null;
        }
        break;
      case PlaybackState.IDLE:
          this.onUpdatePosition();
          this.processingState = ProcessingState.none;
          this.broadcastImmediatePlaybackEvent();
          if (this.prepareResult != null) {
            let response: Map<String, Object> = new Map<String, Object>();
            response.set('duration', -1);
            this.prepareResult.success(response);
            this.prepareResult = null;
          }
          if (this.seekResult != null) {
            this.completeSeek();
          }
        break;
    }
  }

  private updatePositionIfChanged(): boolean {
    let currentPosition = this.getCurrentPosition();
    if (currentPosition == this.updatePosition) {
      return false;
    }
    this.updatePosition = this.getCurrentPosition();
    this.updateTime = systemDateTime.getTime();
    return true;
  }

  public play(result: MethodResult) {
    // 已在真实播放中：忽略重复 play 请求（Dart 端在 load 与 play 并发时可能重复下发）。
    // 这里用 avPlayer 的真实状态 state==PLAY 判断，而非 isPlaying 标志——isPlaying 在 load 时可能被预置为 true（尚未真正播放）。
    if (this.player?.state == AudioPlayerState.PLAY) {
      result.success(new Map<String, Object>());
      return;
    }
    if (this.playResult != null) {
      this.playResult.success(new Map<String, Object>());
    }
    this.playResult = result;
    this.player?.play();
    this.onUpdatePosition();
    this.broadcastPlayerData(true);
    if (this.processingState == ProcessingState.completed && this.playResult != null) {
      this.playResult.success(new Map<String, Object>());
      this.playResult = null;
    }
  }

  public pause(result: MethodResult) {
    this.player?.pause(result);
    this.onUpdatePosition();
    this.broadcastPlayerData(false);
    if (this.playResult != null) {
      this.playResult.success(new Map<String, Object>());
      this.playResult = null;
    }
  }

  /**
   * 通过 data 通道同步 playing 状态给 Dart 端。
   */
  private broadcastPlayerData(isPlaying: boolean) {
    const data: Map<String, Object> = new Map<String, Object>();
    data.set('playing', isPlaying);
    this.dataEventChannel?.success(data);
  }

  private setVolume(volume: number) {
    this.player?.setVolume(volume);
  }

  private setSpeed(speed: number) {
    this.player?.setSpeed(speed);
    this.onUpdatePosition();
    this.enqueuePlaybackEvent();
  }

  private async seek(position: number, index: number | null, result: MethodResult) {
    if (this.processingState == ProcessingState.none || this.processingState == ProcessingState.loading) {
      result.success(new Map<String, Object>());
      return;
    }
    this.abortSeek();
    this.seekPos = position;
    this.seekResult = result;
    try {
      // MediaAvPlayer.seek 为 async（返回 Promise），必须 await/catch，
      // 否则内部同步异常会转为未处理的 rejected Promise，且 Dart 端 seek Future 永久悬挂
      await this.player?.seek(position, index);
    } catch (e) {
      this.seekResult = null;
      this.seekPos = null;
      console.error(TAG, 'seek::error:' + JSON.stringify(e));
      // 必须把异常转换为 result.error() 传播到 Flutter，否则 Dart 端 seek() 不会结束
      result.error('seekError', e instanceof Error ? e.message : JSON.stringify(e), null);
    }
  }

  private abortSeek() {
    if (this.seekResult != null) {
      try {
        this.seekResult.success(new Map<String, Object>());
      } catch (e) {
        console.error(TAG, 'abortSeek::error:' + JSON.stringify(e));
      }
      this.seekResult = null;
      this.seekPos = null;
    }
  }

  async onMethodCall(call: MethodCall, result: MethodResult) {
    try {
      switch (call.method) {
        //开始加载当前音频源，一旦已知或不可用，将立即返回音频时间为null
        case 'load':
          let initialPosition: number = call.argument('initialPosition');
          let initialIndex: number = call.argument('initialIndex');
          await this.load(this.getAudioSource(call.argument('audioSource')),
            initialPosition == null ? AudioPlayer.TIME_UNSET : initialPosition / 1000,
            initialIndex, result);
          break;
      //播放
        case 'play':
          this.play(result);
          break;
      //暂停
        case 'pause':
          this.pause(result);
          break;
      //设置音量
        case 'setVolume':
          let volumeArg: Any = call.argument('volume');
          this.setVolume(volumeArg != null ? volumeArg as number : 0);
          result.success(new Map<String, Object>());
          break;
      //设置速度
        case 'setSpeed':
          if(this.player == null){
            result.error('setSpeed error: player is null',null,null);
            return;
          }
          //如果不在已准备、播放中、暂停、已完成状态下，avPlayer调用setSpeed会提示操作不支持
          if(this.player.state != AudioPlayerState.PREPARED && this.player.state != AudioPlayerState.PLAY
            && this.player.state != AudioPlayerState.PAUSE && this.player.state != AudioPlayerState.COMPLETED){
            // 缓存速度，待播放器就绪后再应用，避免未就绪时速度设置丢失
            const speedArg: Any = call.argument('speed');
            if (speedArg != null) {
              this.pendingSpeed = Number(speedArg);
            }
            result.success(new Map<String, Object>());
            return;
          }
          this.setSpeed(call.argument('speed'));
          result.success(new Map<String, Object>());
          break;
      //设置声音的基频（音调）
      // 平台限制：OHOS AVPlayer 无 pitch 调整 API，此处 no-op，行为与其它平台不一致
        case 'setPitch':
          result.success(new Map<String, Object>());
          break;
      // 平台限制：OHOS AVPlayer 无 skipSilence API，此处 no-op，行为与其它平台不一致
        case 'setSkipSilence':
          result.success(new Map<String, Object>());
          break;
      //设置 LoopMode。
        case 'setLoopMode':
          let loopModeArg: Any = call.argument('loopMode');
          if (loopModeArg == null) {
            result.error('loopMode is null', null, null);
            return;
          }
          let loopModeNum: number = parseInt(loopModeArg as string);
          if (isNaN(loopModeNum) || loopModeNum < 0 || loopModeNum > 2) {
            result.error('loopMode is invalid', null, null);
            return;
          }
          this.player?.setLoopMode(loopModeNum);
          result.success(new Map<String, Object>());
          break;
      //设置是否启用随机播放模式
        case 'setShuffleMode':
          let shuffleModeArg: Any = call.argument('shuffleMode');
          if (shuffleModeArg == null) {
            result.error('shuffleMode is null', null, null);
            break;
          }
          this.player?.setShuffleMode(shuffleModeArg == 1);
          result.success(new Map<String, Object>());
          break;
      //设置随机顺序
        case 'setShuffleOrder':
          let shuffleOrderJson: Map<Any, Any> = call.argument('audioSource');
          if (shuffleOrderJson == null) {
            result.error('audioSource is null', null, null);
            break;
          }
          this.player?.setShuffleOrder(shuffleOrderJson.get('shuffleOrder'));
          this.setShuffleOrder(shuffleOrderJson);
          result.success(new Map<String, Object>());
          break;
        case 'setAutomaticallyWaitsToMinimizeStalling':
          result.success(new Map<String, Object>());
          break;
      //跳转到指定播放位置
        case 'seek':
          let rawPosition: Any = call.argument('position');
          let rawIndex: Any = call.argument('index');
          let position: number = rawPosition != null ? Number(rawPosition) : AudioPlayer.TIME_UNSET;
          let index: number | null = rawIndex != null ? Number(rawIndex) : null;
          this.seek(position == AudioPlayer.TIME_UNSET ? AudioPlayer.TIME_UNSET :
          Number(position) / 1000, index, result);
          break;
        case 'concatenatingInsertAll':
          let insertIndex: Any = call.argument('index');
          let insertChildren: Array<Any> = call.argument('children');
          if (insertIndex == null || insertChildren == null) {
            result.error('index or children is null', null, null);
            break;
          }
          this.player?.addPublicMediaSources(insertIndex,
            this.getAudioSources(insertChildren));
          this.player?.setShuffleOrder(call.argument('shuffleOrder'));
          result.success(new Map<string,object>());
          break;
        case 'concatenatingRemoveRange':
          if (this.player == null) {
            result.error('concatenatingRemoveRange error: player is null', null, null);
            break;
          }
          await this.player.removeMediaSourceRange(call.argument('startIndex'),
            call.argument('endIndex'));
          this.player.setShuffleOrder(call.argument('shuffleOrder'));
          result.success(new Map<string,object>());
          break;
        case 'concatenatingMove':
          let moveCurrentIndex: Any = call.argument('currentIndex');
          let moveNewIndex: Any = call.argument('newIndex');
          if (moveCurrentIndex == null || moveNewIndex == null) {
            result.error('currentIndex or newIndex is null', null, null);
            break;
          }
          this.player?.moveMediaSource(moveCurrentIndex,
            moveNewIndex);
          this.player?.setShuffleOrder(call.argument('shuffleOrder'));
          result.success(new Map<string,object>());
          break;
        // 平台专用方法（OHOS 无对应能力），按参考实现返回 no-op success
        case 'setCanUseNetworkResourcesForLiveStreamingWhilePaused':
        case 'setPreferredPeakBitRate':
        case 'setAllowsExternalPlayback':
          result.success(new Map<String, Object>());
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (err) {
      const businessError = err as BusinessError;
      const errorCode = businessError.code !== undefined ? businessError.code.toString() : null;
      result.error(errorCode ?? 'Error', 'Error: ' + businessError.message, null);
    } finally {
      this.broadcastPendingPlaybackEvent();
    }
  }

  onStartBuffering() {
    this.processingState = ProcessingState.buffering;
    this.broadcastImmediatePlaybackEvent();
  }

  onEndBuffering() {
    this.processingState = ProcessingState.ready;
    this.broadcastImmediatePlaybackEvent();
  }

  private setShuffleOrder(json: Any) {
    let map: Map<Any, Any> = json;
    let id: string = map.get('id');
    let mediaSource: MediaSource = this.mediaSources.get(id) as MediaSource;
    if (mediaSource == null) {
      return;
    }
    switch (map.get('type')) {
      case 'concatenating':
        mediaSource.setShuffleOrder(map.get('shuffleOrder'));
        let children: Array<Object> = map.get('children');
        children.forEach(child => {
          this.setShuffleOrder(child);
        });
        break;
      case 'looping':
        this.setShuffleOrder(map.get('child'));
        break;
    }
  }

  dispose() {
    if (this.processingState == ProcessingState.loading) {
      this.abortExistingConnection();
    }
    if (this.playResult != null) {
      this.playResult.success(new Map<String, Object>());
      this.playResult = null;
    }
    // 若 dispose 时 seek 仍在进行（seekResult 未 null），须完成 seek 的 Future 回调，
    // 否则 Dart 端 seek() 会永久悬挂；dispose 后 MediaAvPlayer 回调已注销，completeSeek 不会再触发
    if (this.seekResult != null) {
      this.seekResult.success(new Map<String, Object>());
      this.seekResult = null;
    }
    this.mediaSources.clear();
    this.mediaSource = null;
    if (this.player != null) {
      this.player.dispose();
      this.player = null;
      this.processingState = ProcessingState.none;
      this.broadcastImmediatePlaybackEvent();
    }
    this.eventChannel?.endOfStream();
    this.eventChannel?.dispose();
    this.dataEventChannel?.endOfStream();
    this.dataEventChannel?.dispose();
    // 取消 MethodChannel handler 并置空，避免通道持有 AudioPlayer 引用导致泄漏
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
    this.eventChannel = null;
    this.dataEventChannel = null;
    // 显式置空待发送事件，避免销毁后仍持有事件引用
    this.pendingPlaybackEvent = null;
  }

  private decodeUri(uri: string): string {
    // 仅对本地文件路径解码百分号转义，避免破坏 http(s) URL 中合法的 %XX 编码语义
    if (uri != null && uri.startsWith('file://')) {
      return decodeURIComponent(uri);
    }
    return uri;
  }

  private decodeAudioSource(json: Any): MediaSource {
    let map: Map<Any, Any> = json;
    let id: string = this.mapGet(map, 'id');
    let type: string = this.mapGet(map, 'type');
    let header: Record<string, string> = this.mapGet(map, 'headers')
    switch (this.mapGet(map, 'type')) {
      case 'progressive':
        let mediaSource: MediaSource = new MediaSource();
        mediaSource
          .setUri(this.decodeUri(this.mapGet(map, 'uri') as string))
          .setId(id)
          .setType(type);
        if (header) {
          mediaSource.setHeader(header);
        }
        return mediaSource;
      case 'dash':
        let dashMediaSource: MediaSource = new MediaSource();
        if (header) {
          dashMediaSource.setHeader(header);
        }
        dashMediaSource
          .setId(id)
          .setType(type).setMimeType('application/dash+xml' as media.AVMimeTypes)
          .setUri(this.decodeUri(this.mapGet(map, 'uri') as string));

        return dashMediaSource;
      case 'hls':
        let hlsMediaSource: MediaSource = new MediaSource();
        if (header) {
          hlsMediaSource.setHeader(header);
        }
        hlsMediaSource
          .setId(id)
          .setType(type).setMimeType(media.AVMimeTypes.APPLICATION_M3U8)
          .setUri(this.decodeUri(this.mapGet(map, 'uri') as string));

        return hlsMediaSource;
      case 'concatenating':
        let mediaSources: Array<MediaSource> = this.getAudioSourcesArray(this.mapGet(map, 'children'));
        let concatenatingMediaSource = new MediaSource();
        concatenatingMediaSource
          .setId(id)
          .setType(type)
          .setMimeType(media.AVMimeTypes.APPLICATION_M3U8)
          .setAtomic(false)
          .setUseLazyPreparation(this.mapGet(map, 'useLazyPreparation') as boolean)
          .setShuffleOrder(this.mapGet(map, 'shuffleOrder'))
          .setChildMediaSource(mediaSources);
        return concatenatingMediaSource;
      case 'clipping':
        let childMediaSource = this.getAudioSource(this.mapGet(map, 'child'));
        // start/end 缺省时分别代表 0 与流末尾，parseInt(null) 会产生 NaN 导致非法夹取区间
        let rawStart: Any = this.mapGet(map, 'start');
        let rawEnd: Any = this.mapGet(map, 'end');
        let start: number = rawStart != null ? Number(rawStart) : 0;
        let end: number = rawEnd != null ? Number(rawEnd) : Number.MAX_SAFE_INTEGER;
        let clippingMediaSource = new MediaSource();
        clippingMediaSource
          .setId(id)
          .setStartUs(start)
          .setEndUs(end)
          // childMediaSource 在 getAudioSource 内已完成 uri 解码，这里不再二次 decodeURIComponent
          .setUri(childMediaSource.getUri())
          .setType(this.mapGet(map, 'type'));
        return clippingMediaSource;
      case 'looping':
        let count: number = this.mapGet(map, 'count');
        let looperChild = this.getAudioSource(this.mapGet(map, 'child'));
        let looperChildren: Array<MediaSource> = new Array<MediaSource>(count)
        for (let i = 0; i < looperChildren.length; i++) {
          looperChildren[i] = looperChild!;
        }
        let loopingMediaSource = new MediaSource();
        loopingMediaSource
          .setChildMediaSource(looperChildren)
          .setAtomic(false)
          .setId(id)
          .setType(type);
        return loopingMediaSource;
      case 'silence':
        // 平台限制：OHOS AVPlayer 无 SilenceMediaSource 等价物，无法真正播放静音源。
        // 直接抛明确错误：若返回空 uri 占位源，loadAsset 会静默跳过加载，play() 时才因无媒体源进入
        // ERROR 状态且不回调 Dart 端，导致界面停在加载态且无任何错误提示。显式报错让 Dart 端可感知。
        throw new Error('SilenceAudioSource is not supported on OHOS');
      default:
        throw new Error('Unknown AudioSource type: ' + this.mapGet(map, 'type'));
    }
  }

  private getAudioSourcesArray(json: Any): Array<MediaSource> {
    let mediaSources: Array<MediaSource> = this.getAudioSources(json);
    return mediaSources;
  }

  private getAudioSources(json: Any): Array<MediaSource> {
    if (!(json instanceof Array)) {
      throw new Error('List expected: ' + json);
    }
    let audioSources: Array<Any> = json;
    let mediaSources: Array<MediaSource> = new Array<MediaSource>();
    for (let i = 0; i < audioSources.length; i++) {
      mediaSources.push(this.getAudioSource(audioSources[i]));
    }
    return mediaSources;
  }

  private mapGet(o: Any, key: String): Any {
    if (o instanceof Map) {
      return o.get(key);
    } else {
      return null;
    }
  }

  private getAudioSource(json: Any): MediaSource {
    let map: Map<Any, Any> = json;
    let id: string = this.mapGet(map, 'id') as string;
    let mediaSource: MediaSource | undefined;
    if (this.mediaSources) {
      mediaSource = this.mediaSources.get(id);
    }
    if (mediaSource == undefined) {
      mediaSource = this.decodeAudioSource(map);
      if (mediaSource) {
        this.mediaSources.set(id, mediaSource);
      }
    }
    return mediaSource;
  }

  private async load(mediaSource: MediaSource, initialPosition: number, initialIndex: number, result: MethodResult) {
    this.pendingSpeed = null;
    // 加载新音源时清空上次错误，避免错误码/信息滞留到新一轮播放
    this.errorCode = null;
    this.errorMessage = null;
    this.initialPos = initialPosition;
    this.initialIndex = initialIndex;
    this.currentIndex = initialIndex != null ? initialIndex : 0;

    switch (this.processingState) {
      case ProcessingState.none:
        break;
      case ProcessingState.loading:
        this.abortExistingConnection();
        this.player?.stop();
        break;
      default:
        this.player?.stop();
        break;
    }
    this.prepareResult = result;
    this.onUpdatePosition();
    this.processingState = ProcessingState.loading;
    await this.enqueuePlaybackEvent();
    this.mediaSource = mediaSource;
    if (this.player) {
      // 底层 load 以 seekPosition = -1 表示'未指定初始位置'，此处将平台哨兵值 TIME_UNSET 归一化为 -1，
      // 避免把极大负数当作真实位置传入；同时确保 initialIndex 缺省时也不再丢失 initialPosition
      let seekPosition: number = this.initialPos != AudioPlayer.TIME_UNSET ? this.initialPos : -1;
      // 不再在 load 时预置 isPlaying=true：仅当用户已显式调用过 play() 时 (isPlaying 已置位) 才延续播放，
      // 与 playWhenReady 语义对齐，避免新建播放器 load 后未经 play() 自动出声
      if (this.initialIndex || this.initialIndex == 0) {
        await this.player.load(mediaSource, this.initialIndex, seekPosition);
      } else {
        await this.player.load(mediaSource, this.currentIndex, seekPosition);
      }
    }
  }

  abortExistingConnection() {
    this.sendError(AudioPlayer.ERROR_ABORT.toString(), 'Connection aborted');
  }

  private sendError(errorCode: string, errorMsg: string, details?: Any) {
    // 记录最近一次错误，供后续 createPlaybackEvent 透传给 Dart 端 PlaybackEvent
    this.errorCode = errorCode;
    this.errorMessage = errorMsg;
    if (this.prepareResult != null) {
      this.prepareResult.error(errorCode, errorMsg, details);
      this.prepareResult = null;
    }

    this.eventChannel?.error(errorCode, errorMsg, details);
    if (this.player){
      this.player.state = AudioPlayerState.ERROR;
      // 通知状态变化
      this.player.mediaAvPlayerStateChangeListener?.onPlaybackStateChanged(PlaybackState.IDLE);
    }

  }

  onUpdatePosition() {
    this.updatePosition = this.getCurrentPosition();
    this.updateTime = systemDateTime.getTime();
  }

  onUpdateBufferedPosition(bufferedPosition: number): void {
    // CACHED_DURATION 回调返回的是'从当前播放头起还能连续播放的缓冲时长(ms)'（相对时长），
    // 而 just_audio 的 bufferedPosition 语义是'从媒体起点到缓冲末尾的绝对位置'，故需叠加当前播放位置，
    // 并钳制到 [当前播放位置, 媒体时长]，以规避不同设备对 CACHED_DURATION 语义的差异导致越界
    let absolutePos: number = this.updatePosition + bufferedPosition;
    let duration: number = this.getDuration();
    if (duration > 0 && absolutePos > duration) {
      absolutePos = duration;
    }
    if (absolutePos < this.updatePosition) {
      absolutePos = this.updatePosition;
    }
    this.bufferedPosition = absolutePos;
  }

  getCurrentPosition(): number {
    // 所有分支统一做非负兜底：AVPlayer 在 ERROR/IDLE/未就绪等状态下 getCurrentTime() 可能返回负值，
    // 若透传给 Dart 端会产出负 Duration，进而导致 SeekBar 的 Slider.value 为负触发断言崩溃
    if (this.initialPos != AudioPlayer.TIME_UNSET) {
      let pos: number = this.initialPos ? this.initialPos : 0;
      return pos < 0 ? 0 : pos;
    } else if (this.processingState == ProcessingState.none || this.processingState == ProcessingState.loading) {
      let pos: number = this.player?.getCurrentTime() ? this.player?.getCurrentTime() : 0;
      return pos < 0 ? 0 : pos;
    } else if (this.seekPos != null && this.seekPos != AudioPlayer.TIME_UNSET) {
      return this.seekPos < 0 ? 0 : this.seekPos;
    } else {
      let pos: number = this.player?.getCurrentTime() ? this.player?.getCurrentTime() : 0;
      return pos < 0 ? 0 : pos;
    }
  }

  completeInitial() {
    this.initialIndex = null;
    this.initialPos = AudioPlayer.TIME_UNSET;
  }

  async enqueuePlaybackEvent() {
    if (this.player?.songList.length == 0) {
      await this.player.avPlayer?.reset();
      this.processingState = ProcessingState.completed;
    }
    let event: Map<String, Object> = new Map<String, Object>();
    this.pendingPlaybackEvent = this.createPlaybackEvent();
  }

  // Creates an event based on the current state.
  private createPlaybackEvent() {
    this.onUpdatePosition();
    let event: Map<String, Object> = new Map<String, Object>();
    let duration: Any = this.getDuration() == AudioPlayer.TIME_UNSET ? null : (1000 * this.getDuration());
    event.set('processingState', this.processingState.valueOf());
    // 下发前对 updatePosition / bufferedPosition 做非负兜底，避免 Dart 端 Slider.value 为负触发断言
    let posMs: number = this.updatePosition > 0 ? 1000 * this.updatePosition : 0;
    let bufMs: number = this.bufferedPosition < 0 ? 0 : 1000 * this.bufferedPosition;
    event.set('updatePosition', posMs);
    event.set('updateTime', this.updateTime);
    // bufferedPosition 与 updatePosition 均已是微秒（1000 * 毫秒），此处不再二次乘 1000，否则会放大 1000 倍
    event.set('bufferedPosition', Math.max(posMs, bufMs));
    event.set('icyMetadata', null as Any);
    event.set('duration', duration);
    event.set('currentIndex', this.currentIndex);
    // just_audio 平台接口读取的字段名为 androidAudioSessionId
    event.set('androidAudioSessionId', this.audioSessionId as Any);
    let errCode: number | null = this.errorCode != null ? Number(this.errorCode) : null;
    if (errCode != null && isNaN(errCode)) {
      errCode = null;
    }
    event.set('errorCode', errCode as Any);
    event.set('errorMessage', this.errorMessage as Any);
    return event;
  }

  private getDuration(): number {
    if (this.processingState == ProcessingState.none || this.processingState == ProcessingState.loading ||
      this.player == null) {
      return AudioPlayer.TIME_UNSET;
    } else {
      return this.player.getDuration() ? this.player.getDuration() : 0;
    }
  }

  // Broadcast the pending playback event if it was set.
  private broadcastPendingPlaybackEvent() {
    if (this.pendingPlaybackEvent != null) {
      this.eventChannel?.success(this.pendingPlaybackEvent);
      this.pendingPlaybackEvent = null;
    }
  }
}
