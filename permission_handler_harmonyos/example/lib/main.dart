import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const PermissionExampleApp());
}

class PermissionExampleApp extends StatelessWidget {
  const PermissionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permission Handler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9333EA))),
      home: const PermissionPage(),
    );
  }
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => PermissionPageState();
}

class PermissionPageState extends State<PermissionPage> {
  static const List<Permission> permissions = <Permission>[
    Permission.camera,
    Permission.microphone,
    Permission.locationWhenInUse,
    Permission.contacts,
    Permission.notification,
  ];

  final Map<Permission, PermissionStatus> statuses = <Permission, PermissionStatus>{};
  final Map<Permission, bool> rationales = <Permission, bool>{};
  ServiceStatus? locationService;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final Map<Permission, PermissionStatus> values = <Permission, PermissionStatus>{};
      final Map<Permission, bool> rationaleValues = <Permission, bool>{};
      for (final Permission permission in permissions) {
        values[permission] = await permission.status;
        rationaleValues[permission] = await permission.shouldShowRequestRationale;
      }
      final ServiceStatus service = await Permission.location.serviceStatus;
      if (!mounted) {
        return;
      }
      setState(() {
        statuses
          ..clear()
          ..addAll(values);
        rationales
          ..clear()
          ..addAll(rationaleValues);
        locationService = service;
        error = null;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '读取权限状态失败: $exception');
    }
  }

  Future<void> request(Permission permission) async {
    setState(() => busy = true);
    try {
      await permission.request();
      await refresh();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '申请权限失败: $exception');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> openSettings() async {
    try {
      final bool opened = await openAppSettings();
      if (!mounted) {
        return;
      }
      setState(() => error = opened ? null : '无法打开应用设置');
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '打开设置失败: $exception');
    }
  }

  String nameOf(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return '相机';
      case Permission.microphone:
        return '麦克风';
      case Permission.locationWhenInUse:
        return '使用期间定位';
      case Permission.contacts:
        return '通讯录';
      case Permission.notification:
        return '通知';
      default:
        return permission.toString();
    }
  }

  IconData iconOf(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return Icons.photo_camera_outlined;
      case Permission.microphone:
        return Icons.mic_none;
      case Permission.locationWhenInUse:
        return Icons.location_on_outlined;
      case Permission.contacts:
        return Icons.contacts_outlined;
      case Permission.notification:
        return Icons.notifications_none;
      default:
        return Icons.help_outline;
    }
  }

  Color statusColor(PermissionStatus status) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (status.isGranted || status.isLimited) {
      return colors.primary;
    }
    if (status.isPermanentlyDenied || status.isDenied) {
      return colors.error;
    }
    return colors.tertiary;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Handler'),
        actions: [IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.refresh), tooltip: '刷新状态')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: '定位服务（serviceStatus）',
            icon: Icons.my_location,
            child: Row(
              children: [
                Icon(
                  locationService == ServiceStatus.enabled ? Icons.check_circle : Icons.cancel,
                  color: locationService == ServiceStatus.enabled ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  locationService == null
                      ? '未知'
                      : locationService == ServiceStatus.enabled
                      ? '定位服务已开启'
                      : '定位服务未开启',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _Section(
            title: '权限列表',
            icon: Icons.lock_outline,
            child: Column(
              children: [
                for (final Permission permission in permissions)
                  _PermissionTile(
                    icon: iconOf(permission),
                    title: nameOf(permission),
                    status: statuses[permission],
                    statusColor: statusColor(statuses[permission] ?? PermissionStatus.denied),
                    rationale: rationales[permission] ?? false,
                    onRequest: busy ? null : () => request(permission),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('openAppSettings() 打开应用设置'),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                error!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'status 读取当前权限状态，request() 申请权限，shouldShowRequestRationale 表示是否需要向用户解释申请理由。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.rationale,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final PermissionStatus? status;
  final Color statusColor;
  final bool rationale;
  final VoidCallback? onRequest;

  String get statusLabel {
    final PermissionStatus? value = status;
    if (value == null) {
      return '未知';
    }
    if (value.isGranted) {
      return '已授权';
    }
    if (value.isLimited) {
      return '部分授权';
    }
    if (value.isPermanentlyDenied) {
      return '已永久拒绝';
    }
    if (value.isRestricted) {
      return '受限';
    }
    if (value.isProvisional) {
      return '临时授权';
    }
    return '未授权';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Row(
        children: [
          Icon(Icons.circle, size: 10, color: statusColor),
          const SizedBox(width: 6),
          Text(statusLabel),
          if (rationale) ...[
            const SizedBox(width: 8),
            Text('· 需说明理由', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
      trailing: FilledButton.tonal(onPressed: onRequest, child: const Text('申请')),
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
