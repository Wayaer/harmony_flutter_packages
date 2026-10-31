import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const ShareExampleApp());
}

class ShareExampleApp extends StatelessWidget {
  const ShareExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDB2777))),
      home: const SharePage(),
    );
  }
}

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => SharePageState();
}

class SharePageState extends State<SharePage> {
  final TextEditingController textController = TextEditingController(text: '来自 Flutter 鸿蒙插件的分享');
  String? result;
  String? error;
  bool busy = false;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> share(ShareParams params) async {
    setState(() => busy = true);
    try {
      final ShareResult shareResult = await SharePlus.instance.share(params);
      if (!mounted) {
        return;
      }
      setState(() {
        result = '分享结果：${shareResult.status.name}';
        error = null;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '分享失败: $exception');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> shareText() => share(ShareParams(text: textController.text, subject: '分享标题'));

  /// share_plus 的 Dart 层会校验 uri 与 text 互斥，因此“文本 + 链接”要把链接拼进正文。
  Future<void> shareTextWithUri() =>
      share(ShareParams(text: '${textController.text}\nhttps://flutter.dev', subject: '分享标题'));

  /// 单独分享一个 URI（不传 text），对应原生的 shareUri。
  Future<void> shareUri() => share(ShareParams(uri: Uri.parse('https://flutter.dev'), subject: '分享标题'));

  Future<void> shareFile() async {
    final Directory directory = Directory.systemTemp;
    final File file = File('${directory.path}/share_demo_${DateTime.now().millisecondsSinceEpoch}.txt');
    try {
      await file.writeAsString(textController.text);
      await share(ShareParams(files: <XFile>[XFile(file.path)], text: '来自 Share Plus 示例'));
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '分享文件失败: $exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Share Plus')),
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
                      Icon(Icons.edit_note, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('分享内容', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '文本内容', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy ? null : shareText,
            icon: const Icon(Icons.share),
            label: const Text('分享文本'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : shareTextWithUri,
            icon: const Icon(Icons.link),
            label: const Text('分享文本 + 链接（拼进正文）'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : shareUri,
            icon: const Icon(Icons.public),
            label: const Text('仅分享链接（URI）'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : shareFile,
            icon: const Icon(Icons.attach_file),
            label: const Text('分享文件（写入临时目录）'),
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            _MessageCard(text: result!, icon: Icons.check_circle_outline, color: theme.colorScheme.primary),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            _MessageCard(text: error!, icon: Icons.error_outline, color: theme.colorScheme.error),
          ],
          const SizedBox(height: 24),
          Text(
            'SharePlus.instance.share 支持纯文本、URI、文件（files）三种形式；uri 与 text 不能同时传入，文本加链接时把链接拼进 text。返回的 ShareResult.status 表示用户是否完成分享。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text, required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
