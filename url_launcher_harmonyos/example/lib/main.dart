import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const UrlLauncherExampleApp());
}

class UrlLauncherExampleApp extends StatelessWidget {
  const UrlLauncherExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Url Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8))),
      home: const UrlLauncherPage(),
    );
  }
}

class UrlLauncherPage extends StatefulWidget {
  const UrlLauncherPage({super.key});

  @override
  State<UrlLauncherPage> createState() => UrlLauncherPageState();
}

class UrlLauncherPageState extends State<UrlLauncherPage> {
  final Uri webUri = Uri.parse('https://flutter.dev');
  final Uri mailUri = Uri.parse('mailto:test@example.com?subject=UrlLauncher%20Demo');
  final Uri telUri = Uri.parse('tel:10086');

  final Map<String, bool> supports = <String, bool>{};
  String? result;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    querySupports();
  }

  Future<void> querySupports() async {
    final Map<String, bool> values = <String, bool>{
      '外部浏览器': await supportsLaunchMode(LaunchMode.externalApplication),
      '应用内浏览器': await supportsLaunchMode(LaunchMode.inAppBrowserView),
      '平台默认': await supportsLaunchMode(LaunchMode.platformDefault),
    };
    final bool canMail = await canLaunchUrl(mailUri);
    final bool canTel = await canLaunchUrl(telUri);
    if (!mounted) {
      return;
    }
    setState(() {
      supports
        ..clear()
        ..addAll(values)
        ..['mailto'] = canMail
        ..['tel'] = canTel;
    });
  }

  Future<void> launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
    WebViewConfiguration? configuration,
  }) async {
    setState(() => busy = true);
    try {
      if (!await canLaunchUrl(uri)) {
        if (!mounted) {
          return;
        }
        setState(() => result = '无法处理该链接：$uri');
        return;
      }
      final bool succeeded = await launchUrl(
        uri,
        mode: mode,
        webViewConfiguration: configuration ?? const WebViewConfiguration(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        result = succeeded ? '已打开：$uri' : '打开失败：$uri';
        error = null;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '打开链接失败: $exception');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> closeInApp() async {
    try {
      await closeInAppWebView();
      if (!mounted) {
        return;
      }
      setState(() => result = '已关闭应用内浏览器');
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '关闭失败: $exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Url Launcher')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: '支持的启动方式',
            icon: Icons.verified_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry<String, bool> entry in supports.entries)
                  Chip(
                    avatar: Icon(entry.value ? Icons.check_circle : Icons.cancel, size: 18),
                    label: Text('${entry.key}：${entry.value ? '支持' : '不支持'}'),
                  ),
              ],
            ),
          ),
          _Section(
            title: '启动链接',
            icon: Icons.open_in_new,
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.public,
                  title: '外部浏览器打开网页',
                  subtitle: 'LaunchMode.externalApplication',
                  onTap: busy ? null : () => launch(webUri, mode: LaunchMode.externalApplication),
                ),
                _ActionTile(
                  icon: Icons.tab,
                  title: '应用内浏览器打开网页',
                  subtitle: 'LaunchMode.inAppBrowserView',
                  onTap: busy
                      ? null
                      : () => launch(
                          webUri,
                          mode: LaunchMode.inAppBrowserView,
                          configuration: const WebViewConfiguration(
                            headers: <String, String>{'harmony_browser_page': 'pages/LaunchInAppPage'},
                          ),
                        ),
                ),
                _ActionTile(
                  icon: Icons.close,
                  title: '关闭应用内浏览器',
                  subtitle: 'closeInAppWebView()',
                  onTap: busy ? null : closeInApp,
                ),
                _ActionTile(
                  icon: Icons.mail_outline,
                  title: '发送邮件',
                  subtitle: 'mailto:',
                  onTap: busy ? null : () => launch(mailUri),
                ),
                _ActionTile(
                  icon: Icons.phone_outlined,
                  title: '拨打电话',
                  subtitle: 'tel:',
                  onTap: busy ? null : () => launch(telUri),
                ),
              ],
            ),
          ),
          if (result != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                result!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          if (error != null)
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
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
