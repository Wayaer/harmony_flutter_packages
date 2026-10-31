// Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import { FlutterPlugin, FlutterPluginBinding} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { FlutterRenderer } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/renderer/FlutterRenderer';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { VideoPlayer } from './VideoPlayer';
import { VideoPlayerApi } from './VideoPlayerApi';
import { CommonConstants } from './CommonConstants';
import { CreateMessage,wrapError,OhosVideoPlayerApi,PlatformVideoViewType } from './Messages';
import { PlayerModel } from './PlayerModel';
import HashMap from '@ohos.util.HashMap';
import { VideoPlayerApiCodec } from './VideoPlayerApiCodec';
import { FlutterState } from './VideoPlayerPlugin';
import resourceManager from '@ohos.resourceManager';
import common from '@ohos.app.ability.common';
import { media } from '@kit.MediaKit';
import { EventChannel } from '@ohos/flutter_ohos';
import { GlobalContext } from './GlobalContext';
import { window } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs';

const TAG: string = "VideoPlayerApiImpl";
const BLACK_COLOR = 0xFF000000;

function mapPlaybackSpeed(speed: number): media.PlaybackSpeed {
  if (speed > 0 && speed <= 0.125) {
    return media.PlaybackSpeed.SPEED_FORWARD_0_125_X;
  } else if (speed > 0.125 && speed <= 0.4) {
    return media.PlaybackSpeed.SPEED_FORWARD_0_25_X;
  } else if (speed > 0.4 && speed <= 0.6) {
    return media.PlaybackSpeed.SPEED_FORWARD_0_50_X;
  } else if (speed > 0.6 && speed <= 0.8) {
    return media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
  } else if (speed > 0.8 && speed <= 1.1) {
    return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  } else if (speed > 1.1 && speed <= 1.4) {
    return media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
  } else if (speed > 1.4 && speed <= 1.6) {
    return media.PlaybackSpeed.SPEED_FORWARD_1_50_X;
  } else if (speed > 1.6 && speed <= 1.8) {
    return media.PlaybackSpeed.SPEED_FORWARD_1_75_X;
  } else if (speed > 1.8 && speed <= 2.0) {
    return media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
  } else if (speed > 2.0) {
    return media.PlaybackSpeed.SPEED_FORWARD_3_00_X;
  }
  return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
}

export class VideoPlayerApiImpl extends OhosVideoPlayerApi{
  private videoPlayers: HashMap<number, VideoPlayer> = new HashMap<number, VideoPlayer>();
  private flutterState: FlutterState | null = null;
  private binding: AbilityPluginBinding | null = null;
  private audioFocus: boolean = false;
  private pixelMaps: HashMap<string, image.PixelMap> = new HashMap();

  constructor(flutterState: FlutterState | null, binding: AbilityPluginBinding | null) {
    super();
    this.flutterState = flutterState;
    this.binding = binding;
  }

  disposeAllPlayers(): void {
    this.videoPlayers.forEach(videoPlayer => videoPlayer?.release());
    this.videoPlayers.clear();
    this.pixelMapRelease();
  }

  initialize(): void {
    Log.i(TAG, "enter initialize")
    this.disposeAllPlayers();
  }

  detach(): void {
    Log.i(TAG, "enter detach")
    this.disposeAllPlayers();
  }

  getContext(): common.UIAbilityContext {
    if (this.binding == null) {
      throw Error("Illegal binding or context state.");
    }
    return this.binding.getAbility().context;
  }

  async createBlackPixelMap(width: number, height: number): Promise<image.PixelMap> {
    const pixels32 = new Uint32Array(width * height);
    pixels32.fill(BLACK_COLOR);
    const opts: image.InitializationOptions = {
      editable: true,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      size: { width, height }
    };
    return image.createPixelMap(pixels32.buffer, opts);
  }

  async create(arg: CreateMessage): Promise<number> {
    let windowClass = await window.getLastWindow(this.getContext())
    GlobalContext.getContext().setObject("windowClass", windowClass)
    Log.i(TAG, "enter create");
    if (this.flutterState == null) {
      throw new Error("Illegal flutterState null.");
    }
    let playerModel = new PlayerModel();
    let flutterRenderer = this.flutterState.getTextureRegistry();
    let uri: string = arg.getUri();
    let asset: string = arg.getAsset();
    let header: Record<string, string> | null = null;
    arg.getHttpHeaders().forEach((value, key) => {
      if (!header) {
        header = {}
      }
      header[key.toString()] = value.toString();
    })
    let textureId: number = flutterRenderer.getTextureId();
    let playerId: number = textureId;
    Log.i(TAG, "enter getRawFd, textureId=" + textureId);
    let surfaceTextureEntry: SurfaceTextureEntry = flutterRenderer.registerTexture(textureId);
    let videoPlayer: VideoPlayer | null = null;
    try {
      let windowProperties = windowClass.getWindowProperties();
      const width = windowProperties.windowRect.width;
      const height = windowProperties.windowRect.height;
      const blackPixelMap = await this.createBlackPixelMap(width, height);
      flutterRenderer.setTextureBackGroundPixelMap(textureId, blackPixelMap);
      this.recordPixelMap(textureId, blackPixelMap);
      if (asset != null) {
        Log.i(TAG, "asset create called, asset is" + asset);
        let avMetaExtractor = await media.createAVMetadataExtractor();
        avMetaExtractor.fdSrc = await this.getContext().resourceManager.getRawFd("flutter_assets/" + asset);
        let mateData = await avMetaExtractor.fetchMetadata();
        if (mateData.hasVideo == CommonConstants.YES) {
          let avImageGenerator = await media.createAVImageGenerator();
          Log.i(TAG, "asset video create");
          avImageGenerator.fdSrc = await this.getContext().resourceManager.getRawFd("flutter_assets/" + asset);
          let pixelMap = await avImageGenerator.fetchFrameByTime(0, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, {
            width: -1,
            height: -1
          });
          avImageGenerator.release();
          flutterRenderer.setTextureBackGroundPixelMap(textureId, pixelMap);
          this.recordPixelMap(textureId, pixelMap);
        }
        avMetaExtractor.release();
      } else if (uri != null && uri.startsWith("fd://")) {
        Log.i(TAG, "local create called, file is" + uri);
        let avMetaExtractor = await media.createAVMetadataExtractor();
        avMetaExtractor.fdSrc = {
          fd: Number.parseInt(uri.replace("fd://", ""))
        };
        let mateData = await avMetaExtractor.fetchMetadata();
        if (mateData.hasVideo == CommonConstants.YES) {
          let avImageGenerator = await media.createAVImageGenerator();
          Log.i(TAG, "local video create");
          avImageGenerator.fdSrc = {
            fd: Number.parseInt(uri.replace("fd://", ""))
          };
          let pixelMap = await avImageGenerator.fetchFrameByTime(0, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, {
            width: -1,
            height: -1
          });
          avImageGenerator.release();
          flutterRenderer.setTextureBackGroundPixelMap(textureId, pixelMap);
          this.recordPixelMap(textureId, pixelMap);
        }
        avMetaExtractor.release();
      }
      let eventChannel: EventChannel = new EventChannel(this.flutterState.getBinaryMessenger(), "flutter.io/videoPlayer/videoEvents" + textureId.toString());
      if (asset != null) {
        let rawFileDescriptor: resourceManager.RawFileDescriptor = await this.getContext().resourceManager.getRawFd("flutter_assets/" + asset);
        videoPlayer = new VideoPlayer(playerModel, surfaceTextureEntry, rawFileDescriptor, null, eventChannel, this.audioFocus, null);
      } else if (uri != null) {
        videoPlayer = new VideoPlayer(playerModel, surfaceTextureEntry, null, uri, eventChannel, this.audioFocus, header);
      } else {
        throw new Error("Invalid video source");
      }
      if (videoPlayer == null) {
        throw new Error("Invalid video source");
      }
      await videoPlayer.createAVPlayer();
      this.videoPlayers.set(playerId, videoPlayer);

      Log.i(TAG, `The player was created successfully,ID: ${playerId}`);
      return playerId;
    } catch (err) {
      if (videoPlayer != null) {
        await videoPlayer.release();
      } else if (uri != null && uri.startsWith("fd://")) {
        try {
          fs.closeSync(Number.parseInt(uri.replace("fd://", "")));
        } catch (e) {
          Log.e(TAG, 'close fd failed: ' + JSON.stringify(e));
        }
      }
      flutterRenderer.unregisterTexture(textureId);
      const pixelMap = this.pixelMaps.get(textureId.toString());
      if (pixelMap) {
        pixelMap.release();
        this.pixelMaps.remove(textureId.toString());
      }
      throw new Error('create video player failed: ' + JSON.stringify(err));
    }
  }

  private recordPixelMap(textureId: number, pixelMap: image.PixelMap): void {
    const key = textureId.toString();
    const previous = this.pixelMaps.get(key);
    this.pixelMaps.set(key, pixelMap);
    if (previous) {
      previous.release();
    }
  }

  pixelMapRelease(){
    for (let pixelMap of this.pixelMaps.values()) {
      if (pixelMap && typeof pixelMap.release === 'function') {
        pixelMap.release();
      }
    }
    this.pixelMaps.clear();
  }

  dispose(playerId:number): void {
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      videoPlayer.release();
      if (this.flutterState) {
        this.flutterState.getTextureRegistry().unregisterTexture(playerId);
      }
      this.videoPlayers.remove(playerId);
      const pixelMap = this.pixelMaps.get(playerId.toString());
      if (pixelMap) {
        pixelMap.release();
        this.pixelMaps.remove(playerId.toString());
      }
      Log.i(TAG, `Release player resources: ${playerId}`);
    } else {
      Log.w(TAG, `Try to release an non-existent player: ${playerId}`);
    }
  }

  setLooping(playerId: number, looping: boolean) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, "setLooping, id=" + playerId + ", videoPlayer=" + videoPlayer);
    if (videoPlayer) {
      videoPlayer.setLooping(looping);
      Log.d(TAG, `Set up the player: ${playerId} loop: ${looping}`);
    } else {
      Log.w(TAG, `The player does not exist: ${playerId}`);
    }
  }

  setVolume(playerId: number, volume: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, "setVolume, id=" + playerId + ", videoPlayer=" + videoPlayer);
   if (videoPlayer) {
      videoPlayer.setVolume(volume);
      Log.d(TAG, `Set up the player: ${playerId} volume: ${volume}`);
    } else {
      Log.w(TAG, `The player does not exist: ${playerId}`);
    }
  }

  setPlaybackSpeed(playerId: number, speed: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, "setPlaybackSpeed, id=" + playerId + ", videoPlayer=" + videoPlayer);
    if (videoPlayer) {
      const enumSpeed = mapPlaybackSpeed(speed);
      if (enumSpeed === null) {
        Log.w(TAG, `Unsupported playback speed, id=${playerId}, Speed=${speed}`);
        videoPlayer.setSpeed(speed);
        return;
      }
      videoPlayer.setSpeed(enumSpeed);
      Log.d(TAG, `Set up the player: ${playerId} speed: ${speed}`);
    } else {
      Log.w(TAG, `The player does not exist: ${playerId}`);
  }
}

  play(playerId: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, "play, id=" + playerId + ", videoPlayer=" + videoPlayer);
    if (videoPlayer != null) {
      videoPlayer.play();
    } else {
      Log.e(TAG, "play  videoPlayer is null");
    }

  }

  position(playerId: number): number {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, "position, id=" + playerId + ", videoPlayer=" + videoPlayer);
    if (videoPlayer) {
      const position = videoPlayer.getPosition();
      Log.d(TAG, `get the player,id=${playerId} position: ${position}`);
      return position;
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
    throw new Error(`VideoError: No player found with playerId <${playerId}>`);
  }

  seekTo(playerId: number, position: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, "seekTo, id=" + playerId + ", videoPlayer=" + videoPlayer);
    if (videoPlayer) {
      videoPlayer.seekTo(position);
      Log.d(TAG, `videoPlayer,id=${playerId} seekTo: ${position}`);
    } else {
      Log.w(TAG, `The player does not exist: ${playerId}`);
    }
  }

  pause(playerId:number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, "pause, id=" + playerId + ", videoPlayer=" + videoPlayer);
    if (videoPlayer) {
      videoPlayer.pause();
      Log.d(TAG, `Pause: ${playerId}`);
    } else {
      Log.w(TAG, `The player does not exist: ${playerId}`);
    }
  }

  setMixWithOthers(mixWithOthers: boolean) {
    Log.d(TAG, "set MixWithOthers:" + mixWithOthers);
    this.audioFocus = mixWithOthers;
     this.videoPlayers.forEach((videoPlayer:VideoPlayer) => {
      videoPlayer.setAudioFocus(mixWithOthers);
    });
  }

  async getAudioTracks(playerId: number): Promise<Array<Map<string, string | number | boolean | null>>> {
    if (playerId < 0) {
      return [];
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      return await videoPlayer.getAudioTracks();
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
    return [];
  }

  async selectAudioTrack(playerId: number, groupIndex: number, trackIndex: number): Promise<void> {
    if (playerId < 0) {
      return;
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      await videoPlayer.selectAudioTrack(groupIndex, trackIndex);
      return;
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
  }

  async getVideoTracks(playerId: number): Promise<Array<Map<string, string | number | boolean | null>>> {
    if (playerId < 0) {
      return [];
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      return await videoPlayer.getVideoTracks();
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
    return [];
  }

  async selectVideoTrack(playerId: number, groupIndex: number, trackIndex: number): Promise<void> {
    if (playerId < 0) {
      return;
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      await videoPlayer.selectVideoTrack(groupIndex, trackIndex);
      return;
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
  }

  setPreventsDisplaySleepDuringVideoPlayback(playerId: number, preventsDisplaySleep: boolean): void {
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      videoPlayer.setPreventsDisplaySleep(preventsDisplaySleep);
      return;
    }
    this.videoPlayers.forEach((player: VideoPlayer) => {
      player.setPreventsDisplaySleep(preventsDisplaySleep);
    });
  }

  setAllowBackgroundPlayback(allowBackgroundPlayback: boolean): void {
    Log.d(TAG, "setAllowBackgroundPlayback: " + allowBackgroundPlayback);
    this.videoPlayers.forEach((player: VideoPlayer) => {
      player.setAllowBackgroundPlayback(allowBackgroundPlayback);
    });
  }

  setup(binaryMessenger: BinaryMessenger): void {
    Log.i(TAG, "设置消息通道处理程序");
    
    this.setupInitializeChannel(binaryMessenger);
    this.setupCreateChannel(binaryMessenger);
    this.setupDisposeChannel(binaryMessenger);
    this.setupSetLoopingChannel(binaryMessenger);
    this.setupSetVolumeChannel(binaryMessenger);
    this.setupSetPlaybackSpeedChannel(binaryMessenger);
    this.setupPlayChannel(binaryMessenger);
    this.setupPositionChannel(binaryMessenger);
    this.setupSeekToChannel(binaryMessenger);
    this.setupPauseChannel(binaryMessenger);
    this.setupSetMixWithOthersChannel(binaryMessenger);
    this.setupGetAudioTracksChannel(binaryMessenger);
    this.setupSelectAudioTrackChannel(binaryMessenger);
    this.setupGetVideoTracksChannel(binaryMessenger);
    this.setupSelectVideoTrackChannel(binaryMessenger);
    this.setupSetPreventsDisplaySleepChannel(binaryMessenger);
    this.setupSetAllowBackgroundPlaybackChannel(binaryMessenger);
  }

  private setupInitializeChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.initialize", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          this.initialize();
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  private setupCreateChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.create", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let createMsg = args[0] as CreateMessage;
        
        try {
          this.create(createMsg).then((playerId: number) => {
            reply.reply([playerId]);
          }).catch((err:Error) => {
            reply.reply(wrapError(err));
          });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  private setupDisposeChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.dispose", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        
        try {
          this.dispose(playerId);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  private setupSetLoopingChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setLooping", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        let looping = args[1] as boolean;
        
        try {
          this.setLooping(playerId, looping);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  private setupSetVolumeChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setVolume", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        let volume = args[1] as number;
        
        try {
          this.setVolume(playerId, volume);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  private setupSetPlaybackSpeedChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setPlaybackSpeed", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        let speed = args[1] as number;
        
        try {
          this.setPlaybackSpeed(playerId, speed);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  private setupPlayChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.play", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        
        try {
          this.play(playerId);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  private setupPositionChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.position", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        
        try {
          let position = this.position(playerId);
          reply.reply([position]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  private setupSeekToChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.seekTo", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        let position = args[1] as number;
        
        try {
          this.seekTo(playerId, position);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  private setupPauseChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.pause", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let playerId = args[0] as number;
        
        try {
          this.pause(playerId);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  private setupSetMixWithOthersChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setMixWithOthers", 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        let args = msg as Array<Object>;
        let mixWithOthers = args[0] as boolean;
        
        try {
          this.setMixWithOthers(mixWithOthers);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  private setupGetAudioTracksChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.getAudioTracks",
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        const args = msg as Array<Object>;
        const playerId = args[0] as number;
        this.getAudioTracks(playerId)
          .then((tracks: Array<Map<string, string | number | boolean | null>>) => {
            reply.reply([tracks]);
          })
          .catch((err: Error) => {
            reply.reply(wrapError(err));
          });
      }
    });
  }

  private setupSelectAudioTrackChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.selectAudioTrack",
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        const args = msg as Array<Object>;
        const playerId = args[0] as number;
        const groupIndex = args[1] as number;
        const trackIndex = args[2] as number;
        this.selectAudioTrack(playerId, groupIndex, trackIndex)
          .then(() => {
            reply.reply([]);
          })
          .catch((err: Error) => {
            reply.reply(wrapError(err));
          });
      }
    });
  }

  private setupGetVideoTracksChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.getVideoTracks",
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        const args = msg as Array<Object>;
        const playerId = args[0] as number;
        this.getVideoTracks(playerId)
          .then((tracks: Array<Map<string, string | number | boolean | null>>) => {
            reply.reply([tracks]);
          })
          .catch((err: Error) => {
            reply.reply(wrapError(err));
          });
      }
    });
  }

  private setupSelectVideoTrackChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.selectVideoTrack",
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        const args = msg as Array<Object>;
        const playerId = args[0] as number;
        const groupIndex = args[1] as number;
        const trackIndex = args[2] as number;
        this.selectVideoTrack(playerId, groupIndex, trackIndex)
          .then(() => {
            reply.reply([]);
          })
          .catch((err: Error) => {
            reply.reply(wrapError(err));
          });
      }
    });
  }

  private setupSetPreventsDisplaySleepChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setPreventsDisplaySleepDuringVideoPlayback",
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        const args = msg as Array<Object>;
        const playerId = args[0] as number;
        const preventsDisplaySleep = args[1] as boolean;
        try {
          this.setPreventsDisplaySleepDuringVideoPlayback(playerId, preventsDisplaySleep);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  private setupSetAllowBackgroundPlaybackChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      "dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setAllowBackgroundPlayback",
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        const args = msg as Array<Object>;
        const allowBackgroundPlayback = args[0] as boolean;
        try {
          this.setAllowBackgroundPlayback(allowBackgroundPlayback);
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

}
