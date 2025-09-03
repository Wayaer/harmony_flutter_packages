# in\_app\_purchase\_ohos

The Ohos implementation of [`in_app_purchase`][1].

## Usage

This package is [endorsed][2], which means you can simply use `in_app_purchase`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

## Contributing

This plugin utilizes
[json_serializable](https://pub.dev/packages/json_serializable) for the
numerous data structures communicated between the underlying platform layers and Dart. After
modifying any of the serialized data structures, regenerate the serializers by executing
`flutter pub run build_runner build --delete-conflicting-outputs`.
`flutter pub run build_runner watch --delete-conflicting-outputs` will supervise the filesystem for changes.

If you are interested in contributing to the plugin, please consult our
[contribution guidelines](https://github.com/flutter/plugins/blob/main/CONTRIBUTING.md).

[1]: https://pub.dev/packages/in_app_purchase
[2]: https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin
