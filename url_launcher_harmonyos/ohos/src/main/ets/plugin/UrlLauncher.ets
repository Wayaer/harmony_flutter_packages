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
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import Want from '@ohos.app.ability.Want';
import wantConstant from '@ohos.app.ability.wantConstant';
import fileuri from '@ohos.file.fileuri';
import { FlutterError, UrlLauncherApi, UrlLauncherApiCodec, WebViewOptions, BrowserOptions, wrapError } from './Messages';
import common from '@ohos.app.ability.common';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import call from '@ohos.telephony.call';
import i18n from '@ohos.i18n';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import router from '@ohos.router'
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { emitter } from '@kit.BasicServicesKit';

const TAG = 'UrlLauncher'

class SendMessageParams {
  telephone: string = '';
  telephoneFormat: string = '';
  contactName: string = '';
}

export class UrlLauncher implements UrlLauncherApi {
  static LAUNCH_TYPE_TEL: string = 'tel:';
  static LAUNCH_TYPE_WEB_HTTP: string = 'http:';
  static LAUNCH_TYPE_WEB_HTTPS: string = 'https:';
  static LAUNCH_TYPE_MAILTO: string = 'mailto:';
  static LAUNCH_TYPE_SMS: string = 'sms:';
  static LAUNCH_TYPE_FILE: string = 'file:';
  static LAUNCH_TYPE_APP_GALLERY: string = 'store:';
  static LAUNCH_TYPE_ENTERPRISE: string = 'store://enterprise'

  static MMS_BUNDLE_NAME = "com.ohos.mms";
  static MMS_ABILITY_NAME = "com.ohos.mms.MainAbility";
  static MMS_ENTITIES = 'entity.system.home';
  static SMS_QUERY_BODY_REGEX: RegExp = /(?:^|&)body=([^&]*)/;

  private context: common.UIAbilityContext;

  constructor(ctx: common.UIAbilityContext) {
    this.context = ctx;
  }

  getPermission() {
    let array: Array<Permissions> = [
      "ohos.permission.READ_MEDIA",
      "ohos.permission.WRITE_MEDIA",
      "ohos.permission.MEDIA_LOCATION",
      "ohos.permission.GET_BUNDLE_INFO",
      "ohos.permission.DISTRIBUTED_DATASYNC",
    ];

    let atManager = abilityAccessCtrl.createAtManager();
    //requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
    atManager.requestPermissionsFromUser(this.context, array).then((data) => {
      Log.d(TAG, "data type:" + typeof (data));
      Log.d(TAG, "data:" + data);
      Log.d(TAG, "data permissions:" + data.permissions);
      Log.d(TAG, "data result:" + data.authResults);
    }, (err: Error) => {
      Log.e(TAG,'Failed to start ability', JSON.stringify(err));
    });
  }

  canLaunchUrl(url: string): boolean {
    let encodedUri = encodeURI(url);
    // sms、tel、file、mailto 等 scheme 用 bundleManager.canOpenLink 判断会报 17700055，因此这里直接按前缀返回 true
    if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_TEL) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTP) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTPS) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_MAILTO) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_SMS) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_FILE) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_APP_GALLERY)) {
      return true;
    }

    try {
      // 其余 scheme 依赖 bundleManager.canOpenLink 判断，需要在 module.json5 的 querySchemes 中声明前缀，
      // 例如打开 "amapuri://route/plan/?did=xxx" 需配置 "querySchemes": [ "amapuri" ]
      if (bundleManager.canOpenLink(encodedUri)) {
        return true;
      }
      return false;
    } catch (error) {
      Log.e(TAG, 'canOpenLink error: ', JSON.stringify(error));
      return false;
    }
  }

  async launchUrl(url: string, headers: Map<string, string>): Promise<boolean> {
    if (!this.canLaunchUrl(url)) {
      return false;
    }

    this.ensureContext();
    let encodedUri = encodeURI(url);
    Log.d(TAG, 'launchUrl. url:' + url + '  eurl:' + encodedUri);
    if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_TEL)) {
      return await this.launchTel(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTP) ||
               encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTPS)) {
      return await this.launchWeb(url, headers);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_MAILTO)) {
      return await this.launchMail(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_SMS)) {
      return await this.launchSms(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_FILE)) {
      return await this.launchFile(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_ENTERPRISE)) {
      return await this.launchOther(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_APP_GALLERY)) {
      return await this.launchAppGallery(url);
    } else {
      return await this.launchOther(url);
    }
  }

  format(number: string) {
    let regex: RegExp = new RegExp('/[\s]/g');
    let phoneNumber = number.replace(regex, '');
    let countryId = i18n.getSystemRegion();
    let phoneNumberFormat= new i18n.PhoneNumberFormat(countryId);
    let isNumberValid:boolean = phoneNumberFormat.isValidNumber(phoneNumber);
    let formatNumber = isNumberValid ? phoneNumberFormat.format(phoneNumber) : phoneNumber;
    return formatNumber;
  }

  async launchSms(url: string): Promise<boolean> {
    let smsUrl = this.parseUrl(url, UrlLauncher.LAUNCH_TYPE_SMS);
    let phoneNumber: string = '';
    let messageBody: string = '';

    let questionMarkIndex = smsUrl.indexOf('?');
    if (questionMarkIndex !== -1) {
      let queryString = smsUrl.substring(questionMarkIndex + 1);
      phoneNumber = smsUrl.substring(0, questionMarkIndex);
      let bodyMatch = queryString.match(UrlLauncher.SMS_QUERY_BODY_REGEX);
      if (bodyMatch) {
        try {
          messageBody = decodeURIComponent(bodyMatch[1]);
        } catch (e) {
          Log.e(TAG, 'decodeURIComponent failed for sms body, raw: ' + bodyMatch[1]);
          messageBody = bodyMatch[1];
        }
      }
    } else {
      phoneNumber = smsUrl;
    }
    try {
      phoneNumber = decodeURIComponent(phoneNumber).replace(/\s+/g, '');
    } catch (e) {
      Log.e(TAG, 'decodeURIComponent failed for phone number, raw: ' + phoneNumber);
      phoneNumber = phoneNumber.replace(/\s+/g, '');
    }
    let formatNum = this.format(phoneNumber);

    let msgParam = new SendMessageParams();
    msgParam.telephone = phoneNumber;
    msgParam.telephoneFormat = formatNum;

    let params = new Array<SendMessageParams>();
    params.push(msgParam);

    let actionData: ESObject = {};
    actionData.contactObjects = JSON.stringify(params);
    actionData.pageFlag = 'conversation';
    if (messageBody) {
      actionData.content = messageBody;
    }
    let str : Want = {
      'bundleName': UrlLauncher.MMS_BUNDLE_NAME,
      'abilityName': UrlLauncher.MMS_ABILITY_NAME,
      'parameters': actionData,
      'entities': [
        UrlLauncher.MMS_ENTITIES,
      ]
    };
    Log.i(TAG, 'jumpToMms want: %s', JSON.stringify(params));
    try {
      await this.context.startAbility(str);
      Log.i(TAG, 'jumpToMms success.');
      return true;
    } catch (error) {
      Log.e(TAG, 'jumpToMms failed: %s', JSON.stringify(error));
      return false;
    }
  }

  async launchTel(url: string): Promise<boolean> {
    let phoneNum = this.parseUrl(url, UrlLauncher.LAUNCH_TYPE_TEL);
    try {
 	    phoneNum = decodeURIComponent(phoneNum).replace(/\s+/g, '');
 	  } catch (e) {
 	    phoneNum = phoneNum.replace(/\s+/g, '');
 	  };
 	  Log.d(TAG, 'launchTel:' + phoneNum);
    try {
      await call.makeCall(phoneNum);
      Log.e(TAG, `launchTel success`);
      return true;
    } catch (err) {
      Log.e(TAG, `launchTel failed,  error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 只支持沙箱路径
  async launchFile(url: string): Promise<boolean> {
    let fileUrl = this.parseUrl(url, UrlLauncher.LAUNCH_TYPE_FILE + '://');
    let fileName = url.substring(url.lastIndexOf('/') + 1);
    let filePath = this.context.filesDir + '/' + fileName;
    let uriFromPath = fileuri.getUriFromPath(filePath);
    Log.d(TAG, 'launchFile:' + fileUrl + '  uriFromPath:' + uriFromPath);
    let want: Want = {
      flags: wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
      // 配置分享应用的隐式拉起规则
      action: 'ohos.want.action.viewData',
      uri: uriFromPath,
    }
    try {
      await this.context.startAbility(want);
      Log.i(TAG, 'Invoke getCurrentBundleStats succeeded.');
      return true;
    } catch (err) {
      Log.e(TAG, `Invoke startAbility failed, code is ${err.code}, message is ${err.message}`);
      return false;
    }
  }

  async launchWeb(url: string, headers: Map<string, string>): Promise<boolean> {
    Log.d(TAG, 'launchWeb url:' + url);
    let params: Record<string, Object>  = {};

    for (let val of headers) {
      params[val[0]] = val[1]
    }

    let want: Want = {
      uri: url,
      parameters: params,
      entities: ['entity.system.browsable'],
      action: 'ohos.want.action.viewData',
    }
    try {
      await this.context.startAbility(want)
    } catch (e) {
      Log.e(TAG, 'launchWeb failed. err:' + JSON.stringify(e))
      return false
    }
    return true;
  }

  async launchMail(url: string): Promise<boolean> {
    // 邮件应用需要带 mailto: scheme 的完整 URI 才能正确匹配收件人。
    let want: Want = {
      uri: url,
      action: 'ohos.want.action.sendToData',
    }
    try {
      await this.context.startAbility(want)
    } catch (e) {
      Log.e(TAG, 'launchMail failed. err:' + JSON.stringify(e))
      return false
    }
    return true;
  }

  // 跳转应用商店详情页，参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-ability-kit#section42001122242
  async launchAppGallery(url: string): Promise<boolean> {
    Log.d(TAG, 'launchAppGallery:' + url);
    // url 格式示范 store://appgallery.huawei.com/app/detail?id=C5765880207855137621
    let want: Want = {
      'action': 'ohos.want.action.appdetail',
      'uri': url,
    };
    try {
      await this.context.startAbility(want)
    } catch (e) {
      Log.e(TAG, 'launchAppGallery failed. err:' + JSON.stringify(e))
      return false
    }
    return true
  }

  async launchOther(url: string): Promise<boolean> {
    let want: Want = {
      uri: url,
    }
    try {
      await this.context.startAbility(want)
    } catch (e) {
      Log.e(TAG, 'launchOther failed. err:' + JSON.stringify(e))
      return false
    }
    return true;
  }

  parseUrl(url: string, prefix: string): string {
    if (url == null || url == undefined) {
      return ''
    }
    // 只去除开头的协议前缀，避免误删 URL 中其他位置的相同字符串。
    return url.startsWith(prefix) ? url.substring(prefix.length) : url;
  }

  private ensureContext(): void {
    if (this.context == null) {
      throw new FlutterError(
        "NO_ACTIVITY", "Launching a URL requires a foreground activity.", null);
    }
  }

  openUrlInWebView(url: string, options: WebViewOptions, browserOptions: BrowserOptions): boolean {
    let headers = options.getHeaders();
    if (!headers.has('harmony_browser_page')) {
      promptAction.showToast({
        message: '请在 launch 函数的 headers 参数中添加 harmony_browser_page 和对应的值，并在鸿蒙工程中增加对应的页面和配置路由',
      });
      return false;
    }
    let harmonyBrowserPage = headers.get('harmony_browser_page');

    let headerMap: Record<string, string> = {};
    headers.forEach((value: string, key: string) => {
      if (key !== 'harmony_browser_page') {
        headerMap[key] = value;
      }
    });

    // 路由参数需要可序列化的普通对象，不能直接传自定义类实例
    const webViewOptions: Record<string, Object> = {
      'enableJavaScript': options.getEnableJavaScript(),
      'enableDomStorage': options.getEnableDomStorage(),
    };
    const browserOptionsMap: Record<string, Object> = {
      'showTitle': browserOptions.getShowTitle(),
    };
    router.pushUrl({
      url: harmonyBrowserPage,
      params: {
        'url': url,
        'options': webViewOptions,
        'headers': headerMap,
        'browserOptions': browserOptionsMap,
      }
    }).catch((error: BusinessError) => {
      Log.e(TAG, 'Failed to open url: ', harmonyBrowserPage, ', Error: ', JSON.stringify(error));
      if (error.code == 100002) {
        promptAction.showToast({
          message: `页面 "${harmonyBrowserPage}" 不存在， 请在鸿蒙工程中创建该页面并注册路由。`,
        });
      }
    });
    return true;
  }

  closeWebView(): boolean {
      emitter.emit("closeWebView");
      return true
  }

  getCodec(): MessageCodec<ESObject> {
    return UrlLauncherApiCodec.INSTANCE;
  }

  setup(binaryMessenger: BinaryMessenger, api: UrlLauncherApi) {
    {
      if (binaryMessenger == null) {
        return;
      }
      let channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.pigeon.UrlLauncherApi.canLaunchUrl", this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let urlArg = args[0] as string;
            try {
              let output = api.canLaunchUrl(urlArg);
              wrapped.push(output);
            } catch (err) {
              let errs = wrapError(err);
              wrapped = errs;
            }
            reply.reply(wrapped)
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.UrlLauncherApi.launchUrl", this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let args = msg as Array<Object>;
            let urlArg = args[0] as string;
            let headersArg = args[1] as Map<string, string>;
            try {
              api.launchUrl(urlArg, headersArg).then((output: boolean) => {
                let result = new Array<Object>();
                result.push(output);
                reply.reply(result);
              }).catch((err: ESObject) => {
                reply.reply(wrapError(err));
              });
            } catch (err) {
              reply.reply(wrapError(err));
            }
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.UrlLauncherApi.openUrlInWebView", this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let urlArg = args[0] as string;
            let optionsArg = args[1] as WebViewOptions;
            let browserOptionsArg = args[2] as BrowserOptions;
            try {
              let output = api.openUrlInWebView(urlArg, optionsArg, browserOptionsArg);
              wrapped.push(output);
            } catch (err) {
              let errs = wrapError(err);
              wrapped = errs;
            }
            reply.reply(wrapped)
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.UrlLauncherApi.closeWebView", this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let wrapped = new Array<Object>();
            try {
              let output = api.closeWebView();
              wrapped.push(output);
            } catch (err) {
              let errs = wrapError(err);
              wrapped = errs;
            }
            reply.reply(wrapped)
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
  }
}