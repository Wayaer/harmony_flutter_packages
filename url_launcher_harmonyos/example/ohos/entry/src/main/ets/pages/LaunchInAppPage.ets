import { InAppBrowser } from 'url_launcher_harmonyos/src/main/ets/plugin/InAppBrowser';

@Entry
@Component
struct LaunchInAppPage {
  build() {
    Row() {
      InAppBrowser()
    }
  }
}
