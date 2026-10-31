/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import common from '@ohos.app.ability.common';
import UIAbility from '@ohos.app.ability.UIAbility';
import List from '@ohos.util.List';
import fs from '@ohos.file.fs';
import { fileUri } from '@kit.CoreFileKit';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';

const TAG = 'Share';
const SHARE_UNAVAILABLE = 'dev.fluttercommunity.plus/share/unavailable';
const SHARE_DISMISSED = '';

export default class Share {
  public context: common.Context | null = null;
  public ability?: UIAbility | null = null;

  constructor(context: common.Context, ability?: UIAbility) {
    this.context = context;
    this.ability = ability ?? null;
  }

  public setAbility(ability: UIAbility | null): void {
    this.ability = ability;
  }

  public async share(
    text: string | null,
    subject: string | null,
    title: string | null,
    withResult: boolean,
    result: MethodResult): Promise<void> {
    const content: string = text ?? '';
    const record: systemShare.SharedRecord = {
      utd: uniformTypeDescriptor.getUniformDataTypeByMIMEType('text/plain'),
      content: content,
      title: title ?? subject ?? content,
    };
    const data = new systemShare.SharedData(record);
    this.startShare(data, withResult, result);
  }

  public async shareFiles(
    paths: List<string> | null,
    mimeTypes: List<string> | null,
    text: string | null,
    subject: string | null,
    title: string | null,
    withResult: boolean,
    result: MethodResult): Promise<void> {
    Log.i(TAG, "shareFiles");
    const shareText: string = text ?? '';
    this.clearShareCacheFolder();
    let fileUris: Array<string> = [];
    try {
      fileUris = paths == null ? [] : await this.getUrisForPaths(paths);
    } catch (err) {
      Log.e(TAG, 'Failed to copy files to share cache: ' + JSON.stringify(err));
      if (withResult) {
        result.error('share_error', JSON.stringify(err), null);
        return;
      }
    }

    if (fileUris.length == 0) {
      if (shareText.length > 0) {
        this.share(shareText, subject, title, withResult, result);
      } else if (withResult) {
        result.success(SHARE_UNAVAILABLE);
      }
      return;
    }

    let data: systemShare.SharedData;
    if (fileUris.length == 1) {
      const record: systemShare.SharedRecord = {
        utd: this.getUniformTypeDescriptor(fileUris[0]),
        uri: fileUris[0],
        content: shareText,
        label: subject ?? undefined,
        title: title ?? subject ?? undefined,
      };
      data = new systemShare.SharedData(record);
    } else {
      if (shareText.length > 0) {
        const textRecord: systemShare.SharedRecord = {
          utd: uniformTypeDescriptor.getUniformDataTypeByMIMEType('text/plain'),
          content: shareText,
          title: title ?? subject ?? undefined,
          label: subject ?? undefined,
        };
        data = new systemShare.SharedData(textRecord);
      } else {
        const firstRecord: systemShare.SharedRecord = {
          utd: this.getUniformTypeDescriptor(fileUris[0]),
          uri: fileUris[0],
        };
        data = new systemShare.SharedData(firstRecord);
        fileUris = fileUris.slice(1);
      }
      fileUris.forEach((uri: string) => {
        const record: systemShare.SharedRecord = {
          utd: this.getUniformTypeDescriptor(uri),
          uri: uri,
        };
        data.addRecord(record);
      });
    }
    this.startShare(data, withResult, result);
  }

  private startShare(data: systemShare.SharedData, withResult: boolean, result: MethodResult): void {
    const context = this.ability?.context;
    if (context == null) {
      Log.w(TAG, 'startShare: ability context is null');
      if (withResult) {
        result.success(SHARE_UNAVAILABLE);
      }
      return;
    }
    // 同一次分享只回复 Dart 一次：dismiss 与 show 异常都可能触发回复。
    let replied: boolean = false;
    const replySuccess = (value: string): void => {
      if (replied) {
        return;
      }
      replied = true;
      result.success(value);
    };
    try {
      const controller = new systemShare.ShareController(data);
      if (withResult) {
        controller.on('dismiss', () => {
          replySuccess(SHARE_DISMISSED);
        });
      }
      controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.BATCH
      });
    } catch (err) {
      Log.e(TAG, 'startShare failed: ' + JSON.stringify(err));
      if (withResult) {
        replySuccess(SHARE_UNAVAILABLE);
      }
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
    const uris: Array<string> = [];
    for (const path of paths) {
      if (this.fileIsInShareCache(path)) {
        throw new Error(`Shared file can not be located in '${this.shareCacheFolder()}'`);
      }
      const file = await this.copyToShareCacheFolder(path);
      uris.push(fileUri.getUriFromPath(file));
    }
    return uris;
  }

  private fileIsInShareCache(file: string): boolean {
    try {
      const fileHandle: fs.File = fs.openSync(file);
      try {
        const parent: string = fileHandle.getParent();
        return parent.startsWith(this.shareCacheFolder());
      } finally {
        fs.closeSync(fileHandle);
      }
    } catch (err) {
      Log.e(TAG, 'fileIsInShareCache failed: ' + JSON.stringify(err));
      return false;
    }
  }

  private async clearShareCacheFolder(): Promise<void> {
    try {
      const folder: string = this.shareCacheFolder();
      if (fs.accessSync(folder)) {
        const files = fs.listFileSync(folder);
        if (files.length > 0) {
          files.forEach(item => {
            fs.unlinkSync(folder + '/' + item);
          });
          fs.rmdirSync(folder);
        }
      }
    } catch (err) {
      Log.e(TAG, 'clearShareCacheFolder failed: ' + JSON.stringify(err));
    }
  }

  private async copyToShareCacheFolder(file: string): Promise<string> {
    const folder = this.shareCacheFolder();
    if (!fs.accessSync(folder)) {
      fs.mkdirSync(folder);
    }
    const oldFile: fs.File = fs.openSync(file);
    try {
      const newFile = folder + '/' + oldFile.name;
      fs.copyFileSync(oldFile.fd, newFile);
      return newFile;
    } finally {
      fs.closeSync(oldFile);
    }
  }
}
