import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FileSelectorExampleApp());
}

class FileSelectorExampleApp extends StatelessWidget {
  const FileSelectorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Selector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB45309))),
      home: const FileSelectorPage(),
    );
  }
}

class FileSelectorPage extends StatefulWidget {
  const FileSelectorPage({super.key});

  @override
  State<FileSelectorPage> createState() => FileSelectorPageState();
}

class FileSelectorPageState extends State<FileSelectorPage> {
  static const XTypeGroup textGroup = XTypeGroup(label: '文本文件', extensions: <String>['txt', 'md', 'json']);
  static const XTypeGroup imageGroup = XTypeGroup(label: '图片', mimeTypes: <String>['image/*']);

  final List<XFile> files = <XFile>[];
  final List<String> directories = <String>[];
  String message = '尚未选择任何文件或目录';
  bool busy = false;

  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => message = '操作失败: $exception');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> openSingle() => run(() async {
    final XFile? file = await openFile();
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      files
        ..clear()
        ..add(file);
      directories.clear();
      message = '已选择单个文件：${file.name}';
    });
  });

  Future<void> openMultiple() => run(() async {
    final List<XFile> selected = await openFiles(acceptedTypeGroups: <XTypeGroup>[imageGroup]);
    if (!mounted) {
      return;
    }
    setState(() {
      files
        ..clear()
        ..addAll(selected);
      directories.clear();
      message = '已选择 ${selected.length} 个文件';
    });
  });

  Future<void> pickDirectory() => run(() async {
    final String? path = await getDirectoryPath(confirmButtonText: '选择此目录');
    if (path == null || !mounted) {
      return;
    }
    setState(() {
      directories
        ..clear()
        ..add(path);
      files.clear();
      message = '已选择目录：$path';
    });
  });

  Future<void> pickDirectories() => run(() async {
    final List<String?> selected = await getDirectoryPaths(confirmButtonText: '选择这些目录');
    if (!mounted) {
      return;
    }
    final List<String> validPaths = selected.whereType<String>().toList();
    setState(() {
      directories
        ..clear()
        ..addAll(validPaths);
      files.clear();
      message = '已选择 ${validPaths.length} 个目录';
    });
  });

  Future<void> saveFile() => run(() async {
    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: 'file_selector_demo.txt',
      acceptedTypeGroups: <XTypeGroup>[textGroup],
    );
    if (location == null || !mounted) {
      return;
    }
    String result = '已选择保存位置：${location.path}';
    try {
      await File(location.path).writeAsString('由 File Selector 示例写入，时间：${DateTime.now()}');
      result = '已保存并写入：${location.path}';
    } catch (_) {
      // 部分设备返回的是 file:// URI，dart:io 无法直接写入，这里只展示选择结果。
    }
    if (!mounted) {
      return;
    }
    setState(() => message = result);
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('File Selector')),
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
                      Icon(Icons.filter_alt_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('选择操作', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : openSingle,
                        icon: const Icon(Icons.insert_drive_file_outlined),
                        label: const Text('单个文件'),
                      ),
                      FilledButton.icon(
                        onPressed: busy ? null : openMultiple,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('多个图片'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : pickDirectory,
                        icon: const Icon(Icons.folder_outlined),
                        label: const Text('单个目录'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : pickDirectories,
                        icon: const Icon(Icons.folder_copy_outlined),
                        label: const Text('多个目录'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : saveFile,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('另存为'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (directories.isNotEmpty)
            _Section(
              title: '目录',
              icon: Icons.folder_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final String path in directories)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SelectableText(path, style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
            ),
          if (files.isNotEmpty)
            _Section(
              title: '文件',
              icon: Icons.attachment_outlined,
              child: Column(
                children: [
                  for (final XFile file in files)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.name),
                      subtitle: Text(file.path, maxLines: 1, overflow: TextOverflow.ellipsis),
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
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
