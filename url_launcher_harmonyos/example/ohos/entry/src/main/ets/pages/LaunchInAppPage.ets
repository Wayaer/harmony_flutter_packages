import { InAppBrowser } from 'url_launcher_harmonyos/src/main/ets/InAppBrowser';

@Entry
@Component
struct LaunchInAppPage {
  build() {
    Row() {
      InAppBrowser()
    }
  }
}
