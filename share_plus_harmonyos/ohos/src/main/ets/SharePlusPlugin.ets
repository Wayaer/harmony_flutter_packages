import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCall, MethodCallHandler, MethodResult } from '@ohos/flutter_ohos';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { common, UIAbility } from '@kit.AbilityKit';
import List from '@ohos.util.List';
import { fileUri } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';

const TAG = "SharePlusPlugin";
const CHANNEL_NAME = 'dev.fluttercommunity.plus/share';

export default class SharePlusPlugin implements FlutterPlugin, AbilityAware, MethodCallHandler {
  private methodChannel: MethodChannel | null = null;
  public context: common.Context | null = null;
  public ability?: UIAbility | null = null;

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToAbility(binding: AbilityPluginBinding) {
    this.ability = binding.getAbility()
  }

  onDetachedFromAbility() {
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext()
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.methodChannel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
  }


  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      switch (call.method) {
        case 'share':
          this.share(call, result);
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (err) {
      Log.e(TAG, 'err:' + JSON.stringify(err));
    }
  }


  public async share(call: MethodCall, result: MethodResult): Promise<void> {
    const text = call.argument('text') as string | null
    const uri = call.argument('uri') as string | null
    const subject = call.argument('subject') as string | null
    const title = call.argument('title') as string | null
    const paths = call.argument('paths') as List<string> | null
    // const mimeTypes = call.argument('mimeTypes') as List<string> | null
    const fileNameOverrides = call.argument('fileNameOverrides') as string | null
    this.clearShareCacheFolder()
    let fileUris: Array<string> = paths == null ? [] : await this.getUrisForPaths(paths)
    try {
      let data: systemShare.SharedData | null = null;
      if (fileUris.length == 0) {
        let record: systemShare.SharedRecord = {
          utd: uniformTypeDescriptor.getUniformDataTypeByMIMEType('text/plain'),
          content: uri ?? text ?? "",
          title: title ?? undefined
        }
        data = new systemShare.SharedData(record);
      } else if (fileUris.length == 1) {
        let record: systemShare.SharedRecord = {
          utd: this.getUniformTypeDescriptor(fileUris[0]),
          uri: fileUris[0],
          content: text ?? undefined,
          label: subject ?? undefined,
          title: title ?? fileNameOverrides ?? undefined,
        }
        data = new systemShare.SharedData(record);
      } else {
        if (text) {
          let record: systemShare.SharedRecord = {
            utd: uniformTypeDescriptor.getUniformDataTypeByMIMEType('text/plain'),
            content: text,
            title: title ?? undefined,
            label: subject ?? undefined,
          }
          data = new systemShare.SharedData(record);
        }
        fileUris.forEach((uri: string) => {
          let record: systemShare.SharedRecord = {
            utd: this.getUniformTypeDescriptor(uri),
            uri: uri,
            content: text ?? undefined,
            label: subject ?? undefined,
            title: title ?? fileNameOverrides ?? undefined,
          }
          if (data) {
            data.addRecord(record);
          } else {
            data = new systemShare.SharedData(record);
          }
        })
      }
      const context = this.ability?.context;
      if (data != null && context != null) {
        let controller = new systemShare.ShareController(data);
        controller.on('dismiss', () => {
          result.success('dismiss');
          controller.off("dismiss", () => {
          })
        });

        // api18 才支持
        // controller.on("shareCompleted", (shareResult: systemShare.ShareOperationResult) => {
        //   result.success(shareResult.targetAbilityInfo.name);
        //   controller.off("dismiss", () => {
        //   })
        //   controller.off("shareCompleted")
        // })
        controller.show(this.ability?.context, {
          previewMode: systemShare.SharePreviewMode.DETAIL,
          selectionMode: systemShare.SelectionMode.BATCH
        });
      } else {
        result.success(`${CHANNEL_NAME}/unavailable`);
      }
    } catch (err) {
      result.success(`${CHANNEL_NAME}/unavailable`);
      Log.e(TAG, 'err:' + JSON.stringify(err));
    }
  }

  private getUniformTypeDescriptor(fileUri: string): string {
    const dotIndex = fileUri.lastIndexOf('.');
    if (dotIndex != -1) {
      const fileExtension = '.' + fileUri.substring(dotIndex + 1);
      return uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(fileExtension) ?? 'general.file';
    }
    return 'general.file';
  }

  private shareCacheFolder(): string {
    return this.context?.cacheDir + '/share_plus';
  }

  private async getUrisForPaths(paths: List<string>): Promise<Array<string>> {
    let uris = new Array<string>();
    try {
      paths.forEach(async path => {
        let file: string;
        if (this.fileIsInShareCache(path)) {
          throw new Error(`Shared file can not be located in '${this.shareCacheFolder()}`);
        }
        file = await this.copyToShareCacheFolder(path);
        uris.push(fileUri.getUriFromPath(file));
      })
    } catch (err) {
      Log.e(TAG, 'err:' + JSON.stringify(err));
    }
    return uris
  }

  private fileIsInShareCache(file: string): boolean {
    try {
      let filePath: fs.File = fs.openSync(file);
      let filePathFold = filePath.getParent();
      if (filePathFold.startsWith(this.shareCacheFolder())) {
        return true;
      }
    } catch (err) {
      Log.e(TAG, 'err:' + JSON.stringify(err));
    }
    return false;
  }

  private async clearShareCacheFolder(): Promise<void> {
    try {
      let folder: string = this.shareCacheFolder();
      if (fs.accessSync(folder)) {
        let files = fs.listFileSync(folder);
        if (files.length > 0) {
          files.forEach(item => {
            fs.unlinkSync(folder + '/' + item);
          })
          fs.rmdirSync(folder);
        }
      }
    } catch (err) {
      Log.e(TAG, 'err:' + JSON.stringify(err));
    }
  }

  private async copyToShareCacheFolder(file: string): Promise<string> {
    let folder = this.shareCacheFolder();
    if (!fs.accessSync(folder)) {
      fs.mkdirSync(folder);
    }
    let oldFile: fs.File = fs.openSync(file);
    let newFile = folder + '/' + oldFile.name;
    fs.copyFileSync(oldFile.fd, newFile);
    return newFile
  }
}
