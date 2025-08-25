import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: const Text('WakelockPlus')),
          body: const HomaPage())));
}

class HomaPage extends StatefulWidget {
  const HomaPage({super.key});

  @override
  State<HomaPage> createState() => _HomaPageState();
}

class _HomaPageState extends State<HomaPage> {
  bool? enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getEnabled();
    });
  }

  void getEnabled() async {
    try {
      enabled = await WakelockPlus.enabled;
    } catch (e) {
      debugPrint("WakelockPlusPlugin flutter error:${e.toString()}");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(spacing: 20, children: [
      SizedBox(width: double.infinity),
      ElevatedButton(
          onPressed: () async {
            await WakelockPlus.enable();
            getEnabled();
          },
          child: const Text('enable wakelock')),
      ElevatedButton(
          onPressed: () async {
            await WakelockPlus.disable();
            getEnabled();
          },
          child: const Text('disable wakelock')),
      Text('The wakelock is currently $enabled')
    ]);
  }
}
