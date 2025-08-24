import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'PackageInfoPlus',
        home: Scaffold(
            appBar: AppBar(title: const Text('PackageInfoPlus')),
            body: const HomePage()));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    initPackageInfo();
  }

  Future<void> initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    setState(() {});
  }

  Widget buildTile(String title, String? subtitle) {
    subtitle ??= 'Unknown';
    return ListTile(title: Text(title), subtitle: Text(subtitle));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      buildTile('App name', packageInfo?.appName),
      buildTile('Package name', packageInfo?.packageName),
      buildTile('App version', packageInfo?.version),
      buildTile('Build number', packageInfo?.buildNumber),
      buildTile('Build signature', packageInfo?.buildSignature),
      buildTile('Installer store', packageInfo?.installerStore),
    ]);
  }
}
