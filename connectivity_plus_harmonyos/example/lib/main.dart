import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ConnectivityExampleApp());
}

class ConnectivityExampleApp extends StatelessWidget {
  const ConnectivityExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connectivity Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB))),
      home: const ConnectivityPage(),
    );
  }
}

class ConnectivityPage extends StatefulWidget {
  const ConnectivityPage({super.key});

  @override
  State<ConnectivityPage> createState() => ConnectivityPageState();
}

class ConnectivityPageState extends State<ConnectivityPage> {
  final Connectivity connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? subscription;
  List<ConnectivityResult> results = <ConnectivityResult>[];
  DateTime? updatedAt;
  String? error;

  @override
  void initState() {
    super.initState();
    check();
    subscription = connectivity.onConnectivityChanged.listen(
      apply,
      onError: (Object event) => setError('监听失败: $event'),
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> check() async {
    try {
      apply(await connectivity.checkConnectivity());
    } catch (error) {
      setError('读取失败: $error');
    }
  }

  void apply(List<ConnectivityResult> value) {
    if (!mounted) {
      return;
    }
    setState(() {
      results = value;
      updatedAt = DateTime.now();
      error = null;
    });
  }

  void setError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => error = message);
  }

  bool get isOnline => results.any((ConnectivityResult result) => result != ConnectivityResult.none);

  IconData iconOf(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_alt;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      case ConnectivityResult.bluetooth:
        return Icons.bluetooth;
      case ConnectivityResult.vpn:
        return Icons.vpn_lock;
      case ConnectivityResult.none:
        return Icons.wifi_off;
      case ConnectivityResult.other:
        return Icons.devices_other;
      case ConnectivityResult.satellite:
        return Icons.satellite_alt;
    }
  }

  String labelOf(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return '移动网络';
      case ConnectivityResult.ethernet:
        return '以太网';
      case ConnectivityResult.bluetooth:
        return '蓝牙';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return '无连接';
      case ConnectivityResult.other:
        return '其他';
      case ConnectivityResult.satellite:
        return '卫星网络';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity Plus'),
        actions: [IconButton(onPressed: check, icon: const Icon(Icons.refresh), tooltip: '重新检测')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusBanner(isOnline: isOnline, results: results, labelOf: labelOf, iconOf: iconOf),
          const SizedBox(height: 16),
          _Section(
            title: '当前网络类型',
            icon: Icons.wifi_tethering,
            child: results.isEmpty
                ? Text('尚未获取到网络状态', style: theme.textTheme.bodyMedium)
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final ConnectivityResult result in results)
                        Chip(avatar: Icon(iconOf(result), size: 18), label: Text(labelOf(result))),
                    ],
                  ),
          ),
          _Section(
            title: '检测时间',
            icon: Icons.schedule,
            child: Text(updatedAt == null ? '—' : updatedAt!.toLocal().toString().split('.').first),
          ),
          if (error != null)
            _Section(
              title: '错误',
              icon: Icons.error_outline,
              child: Text(error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          Text(
            'checkConnectivity() 返回当前网络类型，onConnectivityChanged 会在网络切换时自动推送最新结果。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isOnline, required this.results, required this.labelOf, required this.iconOf});

  final bool isOnline;
  final List<ConnectivityResult> results;
  final String Function(ConnectivityResult) labelOf;
  final IconData Function(ConnectivityResult) iconOf;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color background = isOnline ? colors.primaryContainer : colors.errorContainer;
    final Color foreground = isOnline ? colors.onPrimaryContainer : colors.onErrorContainer;
    final ConnectivityResult? primary = results.isEmpty ? null : results.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(primary == null ? Icons.wifi_find : iconOf(primary), size: 44, color: foreground),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? '网络已连接' : '网络未连接',
                  style: theme.textTheme.titleLarge?.copyWith(color: foreground, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  results.isEmpty ? '读取中…' : results.map(labelOf).join(' / '),
                  style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
