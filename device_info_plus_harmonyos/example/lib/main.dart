import 'package:device_info_plus_harmonyos/device_info_plus_harmonyos.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DeviceInfoExampleApp());
}

class DeviceInfoExampleApp extends StatelessWidget {
  const DeviceInfoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Info Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E))),
      home: const DeviceInfoPage(),
    );
  }
}

class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});

  @override
  State<DeviceInfoPage> createState() => DeviceInfoPageState();
}

class DeviceInfoPageState extends State<DeviceInfoPage> {
  final DeviceInfoPlusOhosPlugin deviceInfoPlugin = DeviceInfoPlusOhosPlugin();

  OhosDeviceInfo? info;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!isOhos) {
      if (!mounted) {
        return;
      }
      setState(() => error = '当前平台不是鸿蒙，无法读取鸿蒙设备信息');
      return;
    }
    try {
      final OhosDeviceInfo value = await deviceInfoPlugin.ohosInfo;
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
      setState(() => error = '读取设备信息失败: $exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OhosDeviceInfo? data = info;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info Plus'),
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
                _DeviceBanner(info: data),
                const SizedBox(height: 16),
                _Section(
                  title: '设备信息',
                  icon: Icons.smartphone,
                  rows: [
                    _InfoRow('设备类型', data.deviceType),
                    _InfoRow('厂商', data.manufacture),
                    _InfoRow('品牌', data.brand),
                    _InfoRow('市场名称', data.marketName),
                    _InfoRow('产品系列', data.productSeries),
                    _InfoRow('认证型号', data.productModel),
                    _InfoRow('硬件型号', data.hardwareModel),
                    _InfoRow('ABI 列表', data.abiList),
                  ],
                ),
                _Section(
                  title: '系统版本',
                  icon: Icons.system_update,
                  rows: [
                    _InfoRow('系统名称', data.distributionOSName),
                    _InfoRow('系统版本', data.distributionOSVersion),
                    _InfoRow('API 版本', '${data.distributionOSApiVersion}'),
                    _InfoRow('SDK API', '${data.sdkApiVersion}'),
                    _InfoRow('首个 API 版本', '${data.firstApiVersion}'),
                    _InfoRow('版本类型', data.osReleaseType),
                    _InfoRow('完整版本', data.osFullName),
                    _InfoRow('版本号', data.versionId),
                  ],
                ),
                _Section(
                  title: '构建信息',
                  icon: Icons.build,
                  rows: [
                    _InfoRow('构建类型', data.buildType),
                    _InfoRow('构建时间', data.buildTime),
                    _InfoRow('构建用户', data.buildUser),
                    _InfoRow('构建主机', data.buildHost),
                    _InfoRow('安全补丁', data.securityPatchTag),
                  ],
                ),
                _Section(
                  title: '设备标识',
                  icon: Icons.fingerprint,
                  rows: [
                    _InfoRow('是否为真机', data.isPhysicalDevice ? '是' : '否'),
                    _InfoRow('ODID', data.odId),
                    _InfoRow('序列号', data.serial),
                    _InfoRow('UDID', data.udid),
                  ],
                ),
              ],
            ),
    );
  }
}

class _DeviceBanner extends StatelessWidget {
  const _DeviceBanner({required this.info});

  final OhosDeviceInfo info;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.devices, size: 44, color: colors.onPrimaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.marketName.isEmpty ? info.productModel : info.marketName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${info.brand} ${info.productModel} · ${info.distributionOSVersion}',
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
            width: 108,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '—' : value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
