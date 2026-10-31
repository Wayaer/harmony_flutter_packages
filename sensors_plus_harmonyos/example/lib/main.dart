import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const SensorsExampleApp());
}

class SensorsExampleApp extends StatelessWidget {
  const SensorsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensors Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16A34A))),
      home: const SensorsPage(),
    );
  }
}

class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => SensorsPageState();
}

class SensorsPageState extends State<SensorsPage> {
  final List<StreamSubscription<dynamic>> subscriptions = <StreamSubscription<dynamic>>[];
  final Map<String, String> readings = <String, String>{};
  final Map<String, String> errors = <String, String>{};

  Duration interval = SensorInterval.normalInterval;
  bool running = false;

  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void start() {
    stop();
    subscriptions.add(
      accelerometerEventStream(samplingPeriod: interval).listen(
        (AccelerometerEvent event) => update('加速度计', event.x, event.y, event.z),
        onError: (Object error) => markError('加速度计', error),
        cancelOnError: true,
      ),
    );
    subscriptions.add(
      userAccelerometerEventStream(samplingPeriod: interval).listen(
        (UserAccelerometerEvent event) => update('线性加速度', event.x, event.y, event.z),
        onError: (Object error) => markError('线性加速度', error),
        cancelOnError: true,
      ),
    );
    subscriptions.add(
      gyroscopeEventStream(samplingPeriod: interval).listen(
        (GyroscopeEvent event) => update('陀螺仪', event.x, event.y, event.z),
        onError: (Object error) => markError('陀螺仪', error),
        cancelOnError: true,
      ),
    );
    subscriptions.add(
      magnetometerEventStream(samplingPeriod: interval).listen(
        (MagnetometerEvent event) => update('磁力计', event.x, event.y, event.z),
        onError: (Object error) => markError('磁力计', error),
        cancelOnError: true,
      ),
    );
    subscriptions.add(
      barometerEventStream(samplingPeriod: interval).listen(
        (BarometerEvent event) => updateReading('气压计', '${event.pressure.toStringAsFixed(2)} hPa'),
        onError: (Object error) => markError('气压计', error),
        cancelOnError: true,
      ),
    );
    if (mounted) {
      setState(() => running = true);
    }
  }

  void stop() {
    for (final StreamSubscription<dynamic> subscription in subscriptions) {
      subscription.cancel();
    }
    subscriptions.clear();
    readings.clear();
    errors.clear();
    if (mounted) {
      setState(() => running = false);
    }
  }

  void update(String name, double x, double y, double z) {
    updateReading(name, 'x ${x.toStringAsFixed(2)}   y ${y.toStringAsFixed(2)}   z ${z.toStringAsFixed(2)}');
  }

  void updateReading(String name, String value) {
    if (!mounted) {
      return;
    }
    setState(() {
      readings[name] = value;
      errors.remove(name);
    });
  }

  void markError(String name, Object error) {
    if (!mounted) {
      return;
    }
    setState(() => errors[name] = '不可用: $error');
  }

  void changeInterval(Duration value) {
    interval = value;
    start();
  }

  String intervalLabel(Duration value) {
    if (value == SensorInterval.normalInterval) {
      return '普通';
    }
    if (value == SensorInterval.uiInterval) {
      return 'UI';
    }
    if (value == SensorInterval.gameInterval) {
      return '游戏';
    }
    return '最快';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sensors Plus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('采样间隔', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<Duration>(
                    segments: <ButtonSegment<Duration>>[
                      ButtonSegment<Duration>(
                        value: SensorInterval.normalInterval,
                        label: Text(intervalLabel(SensorInterval.normalInterval)),
                      ),
                      ButtonSegment<Duration>(
                        value: SensorInterval.uiInterval,
                        label: Text(intervalLabel(SensorInterval.uiInterval)),
                      ),
                      ButtonSegment<Duration>(
                        value: SensorInterval.gameInterval,
                        label: Text(intervalLabel(SensorInterval.gameInterval)),
                      ),
                      ButtonSegment<Duration>(
                        value: SensorInterval.fastestInterval,
                        label: Text(intervalLabel(SensorInterval.fastestInterval)),
                      ),
                    ],
                    selected: <Duration>{interval},
                    onSelectionChanged: (Set<Duration> selection) => changeInterval(selection.first),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '选择间隔会重新订阅全部传感器（${intervalLabel(interval)}）',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final String name in <String>['加速度计', '线性加速度', '陀螺仪', '磁力计', '气压计'])
            _SensorCard(name: name, value: readings[name], error: errors[name]),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: running ? stop : start,
            icon: Icon(running ? Icons.stop_circle_outlined : Icons.play_circle_outline),
            label: Text(running ? '停止监听' : '开始监听'),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.name, required this.value, required this.error});

  final String name;
  final String? value;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          error == null ? Icons.sensors : Icons.sensors_off,
          color: error == null ? colors.primary : colors.error,
        ),
        title: Text(name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          error ?? value ?? '等待数据…',
          style: theme.textTheme.bodySmall?.copyWith(color: error == null ? colors.onSurfaceVariant : colors.error),
        ),
        trailing: value != null && error == null ? Icon(Icons.graphic_eq, color: colors.primary) : null,
      ),
    );
  }
}
