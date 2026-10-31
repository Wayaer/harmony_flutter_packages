import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vibration/vibration.dart';
import 'package:vibration_harmonyos/vibration_harmonyos.dart';

void main() {
  runApp(const VibrationExampleApp());
}

class VibrationExampleApp extends StatelessWidget {
  const VibrationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Vibration')),
        body: const VibrationDemoPage(),
      ),
    );
  }
}

class VibrationDemoPage extends StatefulWidget {
  const VibrationDemoPage({super.key});

  @override
  State<VibrationDemoPage> createState() => _VibrationDemoPageState();
}

class _VibrationDemoPageState extends State<VibrationDemoPage> {
  bool? hasVibrator;
  bool? hasAmplitudeControl;

  VibrationHarmonyOS? get harmonyOS {
    final instance = VibrationPlatform.instance;
    return instance is VibrationHarmonyOS ? instance : null;
  }

  @override
  void initState() {
    super.initState();
    loadCapabilities();
  }

  Future<void> loadCapabilities() async {
    final vibrator = await Vibration.hasVibrator();
    final amplitudeControl = await Vibration.hasAmplitudeControl();
    if (!mounted) {
      return;
    }
    setState(() {
      hasVibrator = vibrator;
      hasAmplitudeControl = amplitudeControl;
    });
  }

  Future<void> run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Vibration failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('振动失败：$error')));
    }
  }

  Future<void> vibrateFromFile() async {
    final plugin = harmonyOS;
    if (plugin == null) {
      return;
    }
    final data = await rootBundle.load('assets/haptic_file.json');
    await run(
      () => plugin.vibrate(
        vibrateEffect: VibrateFromFile(
          hapticFd: HapticFileDescriptor(data: data.buffer.asUint8List()),
        ),
        vibrateAttribute: const VibrateAttribute(usage: 'alarm'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plugin = harmonyOS;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '是否有马达：${hasVibrator ?? "未知"}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '是否支持振幅控制：${hasAmplitudeControl ?? "未知"}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => run(() => Vibration.vibrate()),
          child: const Text('默认振动 500ms'),
        ),
        ElevatedButton(
          onPressed: () => run(() => Vibration.vibrate(duration: 1000)),
          child: const Text('振动 1000ms'),
        ),
        if (plugin != null) ...[
          ElevatedButton(
            onPressed: () => run(
              () => plugin.vibrate(
                vibrateEffect: const VibratePreset(count: 100),
                vibrateAttribute: const VibrateAttribute(usage: 'alarm'),
              ),
            ),
            child: const Text('预置效果振动（count: 100）'),
          ),
          ElevatedButton(
            onPressed: vibrateFromFile,
            child: const Text('使用自定义振动配置文件'),
          ),
        ],
        ElevatedButton(
          onPressed: () => run(Vibration.cancel),
          child: const Text('取消振动'),
        ),
        const SizedBox(height: 24),
        TextButton(onPressed: loadCapabilities, child: const Text('重新读取能力')),
      ],
    );
  }
}
