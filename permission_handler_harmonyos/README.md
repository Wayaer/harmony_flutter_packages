<p align="center">
  <h1 align="center"> <code>permission_handler_harmonyos</code> </h1>
</p>

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  permission_handler: ^12.0.1
  permission_handler_harmonyos: ^0.0.1
...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [permission_handler_harmonyos](./example)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.27.4-dev; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## ohos权限配置参考

### [声明权限](https://docs.openharmony.cn/pages/v5.0/zh-cn/application-dev/security/AccessToken/declare-permissions.md)

应用在申请权限时，需要在项目的配置文件中，逐个声明需要的权限，否则应用将无法获取授权。

---

### [权限列表](https://docs.openharmony.cn/pages/v5.0/zh-cn/application-dev/security/AccessToken/permissions-for-all.md)

#### 对所有应用开放

在申请目标权限前，建议开发者先阅读申请应用权限，对权限的工作流程有基本了解后，再结合列表中权限字段的具体说明，判断应用能否申请目标权限，提高开发效率。

---

### 注意事项

    申请权限需要在ohos/entry/src/main/module.json5中声明
