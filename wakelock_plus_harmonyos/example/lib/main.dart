import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(const WakelockExampleApp());
}

class WakelockExampleApp extends StatelessWidget {
  const WakelockExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wakelock Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC2410C))),
      home: const WakelockPage(),
    );
  }
}

class WakelockPage extends StatefulWidget {
  const WakelockPage({super.key});

  @override
  State<WakelockPage> createState() => WakelockPageState();
}

class WakelockPageState extends State<WakelockPage> {
  bool? enabled;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final bool value = await WakelockPlus.enabled;
      if (!mounted) {
        return;
      }
      setState(() {
        enabled = value;
        error = null;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '读取屏幕常亮状态失败: $exception');
    }
  }

  Future<void> setEnabled(bool value) async {
    setState(() => busy = true);
    try {
      if (value) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
      await refresh();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '设置失败: $exception');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> toggle() async {
    setState(() => busy = true);
    try {
      await WakelockPlus.toggle(enable: enabled != true);
      await refresh();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '切换失败: $exception');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isOn = enabled == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wakelock Plus'),
        actions: [IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.refresh), tooltip: '刷新状态')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isOn ? colors.primaryContainer : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  isOn ? Icons.light_mode : Icons.dark_mode_outlined,
                  size: 56,
                  color: isOn ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  isOn ? '屏幕常亮已开启' : '屏幕常亮已关闭',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  isOn ? '应用在前台运行期间屏幕不会自动熄灭' : '屏幕会遵循系统的自动息屏设置',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: busy ? null : toggle,
            icon: Icon(isOn ? Icons.power_settings_new : Icons.wb_sunny_outlined),
            label: Text(isOn ? '关闭常亮' : '开启常亮'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy || isOn ? null : () => setEnabled(true),
                  child: const Text('用 enable() 开启'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy || !isOn ? null : () => setEnabled(false),
                  child: const Text('用 disable() 关闭'),
                ),
              ),
            ],
          ),
          if (error != null) ...[const SizedBox(height: 16), Text(error!, style: TextStyle(color: colors.error))],
          const SizedBox(height: 24),
          _Section(
            title: '说明',
            icon: Icons.info_outline,
            child: Text(
              'WakelockPlus.enabled 读取当前状态，enable()/disable() 直接设置，toggle(enable: true) 在开启/关闭之间切换。',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
