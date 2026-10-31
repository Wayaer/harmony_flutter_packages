# harmony_flutter_packages

Flutter 鸿蒙（OpenHarmony / HarmonyOS）插件集合。所有包均已按下表的上游 Flutter 插件版本完成同步，鸿蒙实现来自对应的社区适配仓库。

## 1. 版本规则

- 鸿蒙插件版本与所适配的上游 Flutter 插件版本保持一致。
  例如 `shared_preferences` 适配 2.5.4，则 `shared_preferences_harmonyos` 版本也为 2.5.4。
- 平台接口依赖（`*_platform_interface`）的约束与所适配的上游 Flutter 插件 pubspec 完全一致。
  例如 `shared_preferences 2.5.4` 声明 `shared_preferences_platform_interface: ^2.4.0`，
  则本包也使用 `^2.4.0`，不使用精确版本。
- Dart 代码直接 import/export 上游应用包时，该应用包同样沿用上游声明的版本约束。
- `implements: <plugin>` 只声明联邦插件关系，**不支持版本号**；版本兼容性由上游插件声明的平台接口约束保证。
- 本地路径依赖只写在 `pubspec_overrides.yaml`，该文件提交到 Git，但不会随包发布到 pub。
- `analysis_options.yaml` 统一启用 `page_width: 120` 与 `always_use_package_imports: true`。
- 更新某个包时，只升级该包及其 `example/`，不改动其他包。

## 2. 参考仓库说明

| 类型 | 地址 | 说明 |
| --- | --- | --- |
| OpenHarmony 官方 SIG | <https://gitcode.com/openharmony-sig/> | OpenHarmony 官方社区，权威度最高，单插件适配仓库多在此组织下 |
| Flutter 鸿蒙社区组织 | <https://gitcode.com/CPF-Flutter/> | 社区维护的 Flutter 插件聚合仓库 |
| 上述仓库别名 | <https://gitcode.com/openharmony-tpc/>、<https://gitcode.com/openharmony-sig/flutter_packages> | 与 `CPF-Flutter/flutter_packages` 内容一致（同一仓库的不同组织地址） |
| 社区仓库（已迁移 AtomGit） | <https://atomgit.com/oh-flutter/> | `oh-flutter` 组织仓库，部分仓库已从 gitcode 迁到 AtomGit |

`flutter_packages` 是 Flutter 官方插件（file_selector、image_picker、path_provider、shared_preferences、url_launcher、video_player、webview_flutter、in_app_purchase 等）的鸿蒙适配聚合仓库；`flutter_plus_plugins` 是 `fluttercommunity/plus_plugins`（connectivity_plus、device_info_plus、package_info_plus、sensors_plus、share_plus）的鸿蒙适配聚合仓库。

## 3. 已同步的插件

### 3.1 flutter/packages 适配（`flutter_packages`）

仓库：<https://gitcode.com/CPF-Flutter/flutter_packages.git>

| 鸿蒙包 | 上游 Flutter 包 | 鸿蒙插件版本 | 分支 | 仓库内目录 |
| --- | --- | --- | --- | --- |
| `file_selector_harmonyos` | `file_selector` | 1.1.0 | `br_file_selector-v1.1.0_ohos` | `file_selector/` |
| `image_picker_harmonyos` | `image_picker` | 1.2.1 | `br_image_picker-v1.2.1_ohos` | `image_picker/` |
| `path_provider_harmonyos` | `path_provider` | 2.1.5 | `br_path_provider-v2.1.5_ohos` | `path_provider/` |
| `shared_preferences_harmonyos` | `shared_preferences` | 2.5.4 | `br_shared_preferences-v2.5.4_ohos` | `shared_preferences/` |
| `url_launcher_harmonyos` | `url_launcher` | 6.3.2 | `br_url_launcher-v6.3.2_ohos` | `url_launcher/` |
| `video_player_harmonyos` | `video_player` | 2.14.1 | `br_video_player-v2.11.1_ohos`（代码基线，已验证兼容 2.14.1） | `video_player/` |
| `webview_flutter_harmonyos` | `webview_flutter` | 4.13.1 | `br_webview_flutter-v4.13.1_ohos` | `webview_flutter/` |

### 3.2 plus_plugins 适配（`flutter_plus_plugins`）

仓库：<https://gitcode.com/CPF-Flutter/flutter_plus_plugins.git>

| 鸿蒙包 | 上游 Flutter 包 | 鸿蒙插件版本 | 分支 | 仓库内目录 |
| --- | --- | --- | --- | --- |
| `connectivity_plus_harmonyos` | `connectivity_plus` | 7.0.0 | `br_connectivity_plus-v7.0.0_ohos` | `connectivity_plus/` |
| `device_info_plus_harmonyos` | `device_info_plus` | 13.3.0 | `br_device_info_plus-v12.3.0_ohos`（代码基线，已验证兼容 13.3.0） | `device_info_plus/` |
| `package_info_plus_harmonyos` | `package_info_plus` | 10.2.2 | `br_package_info_plus-v9.0.0_ohos`（代码基线，已验证兼容 10.2.2） | `package_info_plus/` |
| `sensors_plus_harmonyos` | `sensors_plus` | 7.0.0 | `br_sensors_plus-v7.0.0_ohos` | `sensors_plus/` |
| `share_plus_harmonyos` | `share_plus` | 13.3.1 | `br_share_plus-v12.0.1_ohos`（代码基线，已验证兼容 13.3.1） | `share_plus/` |

### 3.3 单插件适配仓库

| 鸿蒙包 | 上游 Flutter 包 | 鸿蒙插件版本 | 分支 | 仓库地址 | 仓库内目录 |
| --- | --- | --- | --- | --- | --- |
| `permission_handler_harmonyos` | `permission_handler` | 12.0.1 | `br_v12.0.1_ohos` | <https://gitcode.com/openharmony-sig/flutter_permission_handler.git> | `permission_handler/` |
| `wakelock_plus_harmonyos` | `wakelock_plus` | 1.8.2 | `br_v1.4.0_ohos`（代码基线，已验证兼容 1.8.2） | <https://gitcode.com/openharmony-sig/fluttertpc_wakelock_plus.git> | `wakelock_plus/` |

> 仓库内本地依赖统一通过 `pubspec_overrides.yaml` 指向相对路径，示例同样如此。

## 4. 示例程序约定

- 每个包的 `example/` 只保留 ohos 平台。
- 示例只演示少数核心 API，保持可直接运行的最小场景；不堆叠官方示例的全部能力。
- 依赖声明写正常版本（如 `foo_harmonyos: ^1.0.0`），本地路径只写在 `pubspec_overrides.yaml`，示例不会被发布到 pub。
- `example/pubspec.yaml` 必须包含 `publish_to: 'none'`。
- 依赖仓库内其他鸿蒙包时，在 `example/pubspec_overrides.yaml` 里同时指向对应的本地路径。
- 示例代码随对应插件同步更新，并保持 `flutter analyze` 无问题。

## 5. 完整更新指引

以下流程可以直接照做，用于后续把任意一个包更新到新的上游版本。

### 5.1 找到目标版本与分支

1. 查看上游 Flutter 插件最新版本（pub.dev 或 GitHub）。
2. 在对应仓库中查找匹配分支：
   - 聚合仓库分支命名：`br_<插件名>-v<版本>_ohos`，例如 `br_share_plus-v12.0.1_ohos`。
   - 单插件仓库分支命名：`br_v<版本>_ohos`，例如 `br_v1.4.0_ohos`。
3. 用 `git ls-remote --heads <仓库地址>` 确认分支存在。

### 5.2 拉取参考仓库

```bash
# 聚合仓库（只需要目标分支，浅克隆）
git clone --depth 1 --branch <分支> https://gitcode.com/CPF-Flutter/flutter_packages.git /tmp/ref
# 或
git clone --depth 1 --branch <分支> https://gitcode.com/CPF-Flutter/flutter_plus_plugins.git /tmp/ref

# 单插件仓库
git clone --depth 1 --branch <分支> https://gitcode.com/openharmony-sig/flutter_audio_session.git /tmp/ref
git clone --depth 1 --branch <分支> https://gitcode.com/openharmony-sig/fluttertpc_just_audio.git /tmp/ref
git clone --depth 1 --branch <分支> https://gitcode.com/openharmony-sig/flutter_permission_handler.git /tmp/ref
git clone --depth 1 --branch <分支> https://gitcode.com/openharmony-sig/fluttertpc_wakelock_plus.git /tmp/ref

# AtomGit 仓库（网络不稳定时可用部分克隆）
git clone --depth 1 --filter=blob:none --no-checkout -b <分支> https://atomgit.com/oh-flutter/flutter_vibration.git /tmp/ref
cd /tmp/ref && git sparse-checkout init --cone && git sparse-checkout set lib ohos example/lib example/assets && git checkout
```

### 5.3 对比并同步代码

参考仓库中的包目录见第 3 节表格，对齐以下内容：

1. `lib/`：Dart 实现与公开 API。把相对导入统一改成 `package:` 绝对导入（`always_use_package_imports`）。
2. `ohos/`：只同步 `src/main/ets/`、`index.ets`、`src/main/module.json5`、`oh-package.json5`；不要覆盖 `ohos/libs/flutter.har` 相关配置。
3. `pubspec.yaml`：
   - `version` 改为与上游插件一致；
   - 平台接口依赖（`*_platform_interface`）的版本约束与参考仓库/上游插件 pubspec 保持一致；
   - `pluginClass` / `dartPluginClass` 沿用本仓库原有命名，参考仓库只用于内部实现；
   - 仓库内其他鸿蒙包依赖使用版本号，本地路径写入 `pubspec_overrides.yaml`。
4. `example/`：只保留 ohos 平台，依赖写版本号，本地路径写入 `example/pubspec_overrides.yaml`，示例代码按最小可用场景重写。
5. 补全该包的 `README.md`、`CHANGELOG.md`、`example/README.md`，并在本文件第 3 节表格中更新版本与分支。

### 5.4 校验

在包目录执行：

```bash
flutter pub get
dart format lib example/lib
flutter analyze
cd example && flutter analyze
flutter pub publish --dry-run
```

要求包目录与 `example/` 均为 `No issues found`。只格式化本次修改过的 Dart 文件。
`pub publish --dry-run` 应当只提示工作区有未提交改动；本地覆盖已放入 `pubspec_overrides.yaml`，不会再出现依赖覆盖或“约束过紧”警告。

### 5.5 常见差异点

- 参考仓库的 import 可能仍是相对路径，需要改成 `package:`。
- 参考仓库原生目录可能已重构（例如 `components/plugin/`、`dev/fluttercommunity/plus/...`），以参考仓库为准同步，并同步修改 `ohos/index.ets`。
- Pigeon 通道前缀要与平台接口版本一致，例如 `dev.flutter.pigeon.<package>_platform_interface....`。
- 参考仓库的示例可能包含多平台，迁移时只保留 `ohos/`。
- `oh-package.json5` 中的 `@ohos/flutter_ohos` 统一为 `file:libs/flutter.har`。

## 6. 发布与忽略文件

### 6.1 发布前检查

- `pubspec.yaml` 必须包含 `description`（建议 60–180 字符）、`version`、`repository`、`issue_tracker`、`topics`。
- 每个包必须包含 `README.md`、`CHANGELOG.md`、`LICENSE` 与 `example/`。
- `example/pubspec.yaml` 必须包含 `publish_to: 'none'`，本地路径写在 `pubspec_overrides.yaml`。
- 运行 `flutter pub publish --dry-run` 做发布前校验。`pubspec_overrides.yaml` 只用于本地开发，不会随包发布。

### 6.2 忽略与清理

仓库根目录的 `.gitignore` 已统一忽略以下内容，无需在每个包重复配置：

- Dart / Flutter：`.dart_tool/`、`.flutter-plugins`、`.flutter-plugins-dependencies`、`pubspec.lock`、`build/`
- HarmonyOS 生成物：`.hvigor/`、`oh_modules/`、`local.properties`、`oh-package-lock.json5`、
  `package.json`、`package-lock.json`、`node_modules/`、`libs/`
- 示例生成的插件注册文件：`entry/src/main/ets/plugins/`

本地清理命令（不会删除源码）：

```bash
rm -rf */.dart_tool */example/.dart_tool
rm -f */pubspec.lock */example/pubspec.lock */.flutter-plugins */.flutter-plugins-dependencies
rm -rf */ohos/.hvigor */ohos/oh_modules */ohos/libs
rm -rf */example/ohos/.hvigor */example/ohos/oh_modules */example/ohos/node_modules
rm -rf */example/ohos/entry/src/main/ets/plugins
rm -f */ohos/local.properties */example/ohos/local.properties
rm -f */ohos/package.json */ohos/package-lock.json */ohos/oh-package-lock.json5
```

## 7. 校验方式（历史汇总）

每个更新完成的包至少执行：

```bash
flutter pub get
dart format lib example/lib
flutter analyze
```

本次全部 18 个包均已通过上述校验。
