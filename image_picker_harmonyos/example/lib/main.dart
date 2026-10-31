import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const ImagePickerExampleApp());
}

class ImagePickerExampleApp extends StatelessWidget {
  const ImagePickerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Picker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488))),
      home: const ImagePickerPage(),
    );
  }
}

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => ImagePickerPageState();
}

class ImagePickerPageState extends State<ImagePickerPage> {
  final ImagePicker picker = ImagePicker();

  XFile? image;
  XFile? video;
  List<XFile> images = <XFile>[];
  String? message;
  String? error;
  bool busy = false;

  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '操作失败: $exception');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> pickImageFrom(ImageSource source) => run(() async {
    final XFile? file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      image = file;
      video = null;
      images = <XFile>[];
      message = '已选择图片：${file.name}';
      error = null;
    });
  });

  Future<void> pickMultipleImages() => run(() async {
    final List<XFile> selected = await picker.pickMultiImage(imageQuality: 85);
    if (!mounted) {
      return;
    }
    setState(() {
      images = selected;
      image = null;
      video = null;
      message = '已选择 ${selected.length} 张图片';
      error = null;
    });
  });

  Future<void> pickVideoFile() => run(() async {
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 1));
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      video = file;
      image = null;
      images = <XFile>[];
      message = '已选择视频：${file.name}';
      error = null;
    });
  });

  Future<void> pickMediaFile() => run(() async {
    final XFile? file = await picker.pickMedia();
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      video = file;
      image = null;
      images = <XFile>[];
      message = '已选择媒体：${file.name}';
      error = null;
    });
  });

  Widget buildPreview() {
    if (images.isNotEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (BuildContext context, int index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(images[index].path), fit: BoxFit.cover, errorBuilder: imageErrorBuilder),
        ),
      );
    }
    if (image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(File(image!.path), fit: BoxFit.contain, errorBuilder: imageErrorBuilder),
      );
    }
    if (video != null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 48),
            const SizedBox(height: 8),
            Text(video!.name, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Text('尚未选择图片或视频')),
    );
  }

  Widget imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 4),
          Text('无法预览', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Image Picker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : () => pickImageFrom(ImageSource.gallery),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('相册选图'),
                  ),
                  FilledButton.icon(
                    onPressed: busy ? null : () => pickImageFrom(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('拍照'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : pickMultipleImages,
                    icon: const Icon(Icons.collections_outlined),
                    label: const Text('多选图片'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : pickVideoFile,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('选择视频'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : pickMediaFile,
                    icon: const Icon(Icons.perm_media_outlined),
                    label: const Text('选择媒体'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (message != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          if (error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
          buildPreview(),
        ],
      ),
    );
  }
}
