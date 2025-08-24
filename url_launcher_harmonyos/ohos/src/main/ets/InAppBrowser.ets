import web_webview from '@ohos.web.webview';
import router from '@ohos.router';
import { ValueType } from '@kit.ArkData';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { emitter } from '@kit.BasicServicesKit';

@Entry
@Component
export struct InAppBrowser {
  webviewController: web_webview.WebviewController = new web_webview.WebviewController()
  private url?: string;
  private enableJavaScript: boolean = true;
  private enableDomStorage: boolean = true;

  aboutToDisappear() {
    emitter.off("closeWebView");
  }

  aboutToAppear() {
    let params = router.getParams() as Map<string, ValueType>
    this.url = params['url'] as string;
    let options = params['options'] as Map<string, ValueType>;
    this.enableJavaScript = options['enableJavaScript'] as boolean;
    this.enableDomStorage = options['enableDomStorage'] as boolean;
    emitter.once("closeWebView", () => {
      router.back();
      Log.d("InAppBrowser", "closeWebView done");
    })
  }

  build() {
    Row() {
      Web({ src: this.url, controller: this.webviewController })
        .javaScriptAccess(this.enableJavaScript)
        .domStorageAccess(this.enableDomStorage)
    }.width('100%').height('100%')
  }
}
