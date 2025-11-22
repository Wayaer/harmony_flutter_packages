import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vibration/vibration.dart';
import 'package:vibration_harmonyos/vibration_harmonyos.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('Vibration Plugin example app')), body: Center(child: HomePage())));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ElevatedButton(
          child: const Text('Vibrate for default 500ms'),
          onPressed: () {
            Vibration.vibrate();
          }),
      ElevatedButton(
          child: const Text('Vibrate for 1000ms'),
          onPressed: () {
            Vibration.vibrate(duration: 1000);
          }),
      if (isHarmonyOS) ...[
        ElevatedButton(
            child: const Text('Vibrate with VibratePreset'),
            onPressed: () {
              (VibrationPlatform.instance as VibrationHarmonyOS).vibrate(
                  vibrateEffect: const VibratePreset(count: 100),
                  vibrateAttribute: const VibrateAttribute(usage: 'alarm'));
            }),
        ElevatedButton(
            child: const Text('Vibrate  with custom haptic_file'),
            onPressed: () {
              rootBundle.load('assets/haptic_file.json').then((data) {
                (VibrationPlatform.instance as VibrationHarmonyOS).vibrate(
                    vibrateEffect: VibrateFromFile(hapticFd: HapticFileDescriptor(data: data.buffer.asUint8List())),
                    vibrateAttribute: const VibrateAttribute(usage: 'alarm'));
              });
            })
      ] else ...[
        ElevatedButton(
            child: const Text('Vibrate with pattern'),
            onPressed: () {
              const snackBar = SnackBar(
                  content: Text(
                      'Pattern: wait 0.5s, vibrate 1s, wait 0.5s, vibrate 2s, wait 0.5s, vibrate 3s, wait 0.5s, vibrate 0.5s'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              Vibration.vibrate(pattern: [500, 1000, 500, 2000, 500, 3000, 500, 500]);
            }),
        ElevatedButton(
            child: const Text('Vibrate with pattern and amplitude'),
            onPressed: () {
              const snackBar = SnackBar(
                  content: Text(
                'Pattern: wait 0.5s, vibrate 1s, wait 0.5s, vibrate 2s, wait 0.5s, vibrate 3s, wait 0.5s, vibrate 0.5s',
              ));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              Vibration.vibrate(
                  pattern: [500, 1000, 500, 2000, 500, 3000, 500, 500], intensities: [0, 128, 0, 255, 0, 64, 0, 255]);
            }),
      ]
    ]);
  }
}

bool isHarmonyOS = defaultTargetPlatform.name == 'ohos';
