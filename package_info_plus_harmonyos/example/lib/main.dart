import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runApp(const PackageInfoExampleApp());
}

class PackageInfoExampleApp extends StatelessWidget {
  const PackageInfoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Package Info Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED))),
      home: const PackageInfoPage(),
    );
  }
}

class PackageInfoPage extends StatefulWidget {
  const PackageInfoPage({super.key});

  @override
  State<PackageInfoPage> createState() => PackageInfoPageState();
}

class PackageInfoPageState extends State<PackageInfoPage> {
  PackageInfo? info;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final PackageInfo value = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        info = value;
        error = null;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '读取应用信息失败: $exception');
    }
  }

  String formatTime(DateTime? time) {
    if (time == null) {
      return '—';
    }
    return time.toLocal().toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PackageInfo? data = info;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Info Plus'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh), tooltip: '刷新')],
      ),
      body: data == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Text(error!, style: TextStyle(color: theme.colorScheme.error)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AppBanner(info: data),
                const SizedBox(height: 16),
                _Section(
                  title: '应用信息',
                  icon: Icons.apps,
                  rows: [
                    _InfoRow('应用名称', data.appName),
                    _InfoRow('包名', data.packageName),
                    _InfoRow('版本号', data.version),
                    _InfoRow('构建号', data.buildNumber),
                    _InfoRow('安装包签名', data.buildSignature),
                    _InfoRow('安装来源', data.installerStore ?? '—'),
                  ],
                ),
                _Section(
                  title: '安装时间',
                  icon: Icons.schedule,
                  rows: [_InfoRow('安装时间', formatTime(data.installTime)), _InfoRow('更新时间', formatTime(data.updateTime))],
                ),
              ],
            ),
    );
  }
}

class _AppBanner extends StatelessWidget {
  const _AppBanner({required this.info});

  final PackageInfo info;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 44, color: colors.onPrimaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.appName.isEmpty ? info.packageName : info.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${info.version} (build ${info.buildNumber})',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer),
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
  const _Section({required this.title, required this.icon, required this.rows});

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

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
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '—' : value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
