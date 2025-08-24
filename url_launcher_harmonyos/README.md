<p align="center">
  <h1 align="center"> <code>url_launcher_harmonyos</code> </h1>
</p>

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  url_launcher: ^6.3.2
  url_launcher_harmonyos: ^0.0.1
...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [url_launcher_harmonyos](./example)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.27.4-dev; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 权限要求

以下权限中有`system_basic` 权限，而默认的应用权限是 `normal` ，只能使用 `normal` 等级的权限，所以可能会在安装hap包时报错*
*9568289**
，请参考 [文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/bm-tool-V5#ZH-CN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed)
修改应用等级为 `system_basic`

#### 在 entry 目录下的module.json5中添加权限

打开 `entry/src/main/module.json5`，添加：

```yaml
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when": "inuse"
    }
  },
]
```

#### 在 entry 目录下添加申请以上权限的原因

打开 `entry/src/main/resources/base/element/string.json`，添加：

```yaml
{
  "string": [
    {
      "name": "network_reason",
      "value": "使用网络"
    },
  ]
}
```

## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标
> iOS 或 Android 的效果。

| Name                                                                                                                                                                                                                                    | return value | Description          | Type     | ohos Support |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|----------------------|----------|--------------|
| canLaunch(String url)                                                                                                                                                                                                                   | Future<bool> | 检查设备是否可以启动一个特定的URL方案 | function | yes          |
| launch(String url, {required bool useSafariVC,required bool useWebView,required bool enableJavaScript,required bool enableDomStorage,required bool universalLinksOnly,required Map<String, String> headers,String? webOnlyWindowName,}) | Future<bool> | 指定跳转参数Url路径          | function | yes          |
| launchUrl(String url, [LaunchOptions](#LaunchOptions) options)                                                                                                                                                                          | Future<bool> | 指定跳转浏览器并打开Url        | function | yes          |
| closeWebView()                                                                                                                                                                                                                          | Future<void> | 关闭WebView页面          | function | yes          |

### Parameters

| Name               | Description                                          | Type                | ohos Support |
|--------------------|------------------------------------------------------|---------------------|--------------|
| url                | 跳转地址                                                 | String              | yes          |
| useSafariVC        | 是否在Safari视图控制器中打开URL                                 | bool                | yes          |
| useWebView         | 如果设置为null 或false ，则在设备的默认浏览器中打开URL；否则，在WebView中启动URL | bool                | yes          |
| enableJavaScript   | 如果设置为true ，则在WebView中启用JavaScript                    | bool                | yes          | 
| enableDomStorage   | 当该值设置为true ，WebView启用DOM存储                           | bool                | yes          | 
| universalLinksOnly | 用于控制是否仅通过Universal Links打开网页                         | bool                | yes          |
| headers            | 在网页中打开Url时的请求头参数                                     | Map<String, String> | yes          |
| webOnlyWindowName  | 取消设置时的默认行为应该是在新选项卡中打开 URL。                           | String?             | yes          | 

### LaunchOptions

| Name                 | Description                                        | Type                                                    | ohos Support |
|----------------------|----------------------------------------------------|---------------------------------------------------------|--------------|
| mode                 | 启动 URL 所需的模式。                                      | [PreferredLaunchMode](#PreferredLaunchMode)             | yes          |
| webViewConfiguration | 在 [PreferredLaunchMode.inAppWebView] 模式下配置 Web 视图。 | [InAppWebViewConfiguration](#InAppWebViewConfiguration) | yes          | 
| webOnlyWindowName    | 取消设置时的默认行为应该是在新选项卡中打开 URL。                         | String?                                                 | yes          | 

### PreferredLaunchMode

| Name                                              | Description              | Type | ohos Support |
|---------------------------------------------------|--------------------------|------|--------------|
| PreferredLaunchMode.platformDefault               | 启动方式由平台决定                | enum | yes          |
| PreferredLaunchMode.inAppWebView                  | 加载到inAppWebView          | enum | yes          |
| PreferredLaunchMode.externalApplication           | 将 URL 传递给要由其他应用程序处理的     | enum | yes          |
| PreferredLaunchMode.externalNonBrowserApplication | 将 URL 传递给要由另一个非浏览器应用程序处理 | enum | yes          |

### InAppWebViewConfiguration

| Name             | Description                       | Type                | ohos Support |
|------------------|-----------------------------------|---------------------|--------------|
| enableJavaScript | 如果设置为true ，则在WebView中启用JavaScript | bool                | yes          | 
| enableDomStorage | 当该值设置为true ，WebView启用DOM存储        | bool                | yes          | 
| headers          | 在网页中打开Url时的请求头参数                  | Map<String, String> | yes          |
