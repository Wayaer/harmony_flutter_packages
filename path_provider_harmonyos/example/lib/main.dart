import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const PathProviderExampleApp());
}

class PathProviderExampleApp extends StatelessWidget {
  const PathProviderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Path Provider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0891B2))),
      home: const PathProviderPage(),
    );
  }
}

class PathProviderPage extends StatefulWidget {
  const PathProviderPage({super.key});

  @override
  State<PathProviderPage> createState() => PathProviderPageState();
}

class PathProviderPageState extends State<PathProviderPage> {
  final List<_PathEntry> _entries = <_PathEntry>[
    _PathEntry('临时目录', Icons.timer_outlined, () async => <String>[(await getTemporaryDirectory()).path]),
    _PathEntry(
      '文档目录',
      Icons.description_outlined,
      () async => <String>[(await getApplicationDocumentsDirectory()).path],
    ),
    _PathEntry('支持目录', Icons.extension_outlined, () async => <String>[(await getApplicationSupportDirectory()).path]),
    _PathEntry(
      '缓存目录',
      Icons.cleaning_services_outlined,
      () async => <String>[(await getApplicationCacheDirectory()).path],
    ),
    _PathEntry('外部存储', Icons.sd_storage_outlined, () async {
      final Directory? directory = await getExternalStorageDirectory();
      return <String>[if (directory != null) directory.path else '当前设备不支持'];
    }),
    _PathEntry('外部缓存', Icons.sd_card_outlined, () async {
      final List<Directory>? directories = await getExternalCacheDirectories();
      return directories == null || directories.isEmpty
          ? <String>['当前设备不支持']
          : directories.map((Directory d) => d.path).toList();
    }),
    _PathEntry('下载目录', Icons.download_outlined, () async {
      final Directory? directory = await getDownloadsDirectory();
      return <String>[if (directory != null) directory.path else '当前设备不支持'];
    }),
  ];

  final Map<String, List<String>> paths = <String, List<String>>{};
  bool loading = true;
  String? message;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final Map<String, List<String>> result = <String, List<String>>{};
    for (final _PathEntry entry in _entries) {
      try {
        result[entry.title] = await entry.resolve();
      } catch (exception) {
        result[entry.title] = <String>['读取失败: $exception'];
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      paths
        ..clear()
        ..addAll(result);
      loading = false;
    });
  }

  Future<void> writeDemoFile() async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/path_provider_demo.txt');
      await file.writeAsString('由 Path Provider 示例写入，时间：${DateTime.now()}');
      final String content = await file.readAsString();
      if (!mounted) {
        return;
      }
      setState(() {
        message = '已写入并读回 ${file.path}\n内容：$content';
        error = null;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '文件读写失败: $exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Path Provider'),
        actions: [IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.refresh), tooltip: '重新读取')],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final _PathEntry entry in _entries)
                  _PathCard(title: entry.title, icon: entry.icon, paths: paths[entry.title] ?? <String>[]),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: writeDemoFile,
                  icon: const Icon(Icons.edit_document),
                  label: const Text('在文档目录写入并读回文件'),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  _MessageCard(text: message!, icon: Icons.check_circle_outline, color: theme.colorScheme.primary),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  _MessageCard(text: error!, icon: Icons.error_outline, color: theme.colorScheme.error),
                ],
              ],
            ),
    );
  }
}

class _PathEntry {
  const _PathEntry(this.title, this.icon, this.resolve);

  final String title;
  final IconData icon;
  final Future<List<String>> Function() resolve;
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.title, required this.icon, required this.paths});

  final String title;
  final IconData icon;
  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
            for (final String path in paths)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SelectableText(
                  path,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
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
          Expanded(child: SelectableText(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
