import 'dart:async';

import 'package:device_info_plus_harmonyos/device_info_plus_harmonyos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: Text('HarmonyOS Device Info')),
          body: const MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final DeviceInfoPlusPlugin deviceInfoPlugin = DeviceInfoPlusPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    if (defaultTargetPlatform == TargetPlatform.ohos) {
      _deviceData = (await deviceInfoPlugin.harmonyOSInfo).data;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _deviceData.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(spacing: 10, children: [
            Text('${entry.key}: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
                child: Text('${entry.value ?? 'N/A'}',
                    maxLines: 10, overflow: TextOverflow.ellipsis))
          ]),
        );
      }).toList(),
    );
  }

}
