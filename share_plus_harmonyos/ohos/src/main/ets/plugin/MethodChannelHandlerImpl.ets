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
import { MethodCall } from '@ohos/flutter_ohos';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import List from '@ohos.util.List';
import Share from './Share';

const TAG = 'MethodCallHandlerImpl';

export default class MethodChannelHandlerImpl implements MethodCallHandler {
  private share: Share | null = null;

  constructor(share: Share) {
    this.share = share;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    Log.i(TAG, "Received '" + call.method + "' message.");
    try {
      switch (call.method) {
        case 'share':
        case 'shareWithResult': {
          const text = call.argument('text') as string | null;
          const uri = call.argument('uri') as string | null;
          const subject = call.argument('subject') as string | null;
          const title = call.argument('title') as string | null;
          const paths = call.argument('paths') as List<string> | null;
          const mimeTypes = call.argument('mimeTypes') as List<string> | null;
          if (paths != null && paths.length > 0) {
            this.share?.shareFiles(paths, mimeTypes, text, subject, title, true, result);
          } else {
            // uri 与 text 在分享面板中同样作为文本内容传递
            this.share?.share(text ?? uri, subject, title, true, result);
          }
          break;
        }
        case 'shareUri': {
          this.share?.share(call.argument('uri') as string, null, call.argument('title') as string, true, result);
          break;
        }
        case 'shareFiles':
        case 'shareFilesWithResult': {
          this.share?.shareFiles(
            call.argument('paths') as List<string> | null,
            call.argument('mimeTypes') as List<string> | null,
            call.argument('text') as string | null,
            call.argument('subject') as string | null,
            call.argument('title') as string | null,
            true,
            result);
          break;
        }
        default:
          result.notImplemented();
          break;
      }
    } catch (err) {
      Log.e(TAG, 'err:' + JSON.stringify(err));
      result.error('share_error', JSON.stringify(err), null);
    }
  }
}
