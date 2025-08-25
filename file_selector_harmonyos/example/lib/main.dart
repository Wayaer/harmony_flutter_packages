import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Selector',
        home: Scaffold(
            appBar: AppBar(title: const Text('File Selector')),
            body: SingleChildScrollView(child: const HomePage())));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<XFile> selectedFiles = <XFile>[];

  @override
  Widget build(BuildContext context) {
    return Column(spacing: 12, children: [
      SizedBox(width: double.infinity),
      ElevatedButton(
          onPressed: openTextFile, child: const Text('Open a text file')),
      ElevatedButton(
        onPressed: openImageFile,
        child: const Text('Open an image'),
      ),
      ElevatedButton(
          onPressed: openImageFiles, child: const Text('Open multiple images')),
      const SizedBox(height: 10),
      ...selectedFiles.map((e) => Container(
          margin: EdgeInsets.symmetric(horizontal: 12),
          width: double.infinity,
          child: Text(e.path, maxLines: 4)))
    ]);
  }

  Future<void> openTextFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'text',
      extensions: <String>['txt', 'json'],
      uniformTypeIdentifiers: <String>['public.text'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    selectedFiles = [file];
    setState(() {});
  }

  Future<void> openImageFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: <String>['jpg', 'png'],
      uniformTypeIdentifiers: <String>['public.image'],
    );
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;
    selectedFiles = [file];
    setState(() {});
  }

  Future<void> openImageFiles() async {
    const XTypeGroup jpgsTypeGroup = XTypeGroup(
      label: 'JPEGs',
      extensions: <String>['jpg', 'jpeg'],
      uniformTypeIdentifiers: <String>['public.jpeg'],
    );
    const XTypeGroup pngTypeGroup = XTypeGroup(
      label: 'PNGs',
      extensions: <String>['png'],
      uniformTypeIdentifiers: <String>['public.png'],
    );
    final files = await openFiles(acceptedTypeGroups: <XTypeGroup>[
      jpgsTypeGroup,
      pngTypeGroup,
    ]);
    if (files.isEmpty) return;
    selectedFiles = files;
    setState(() {});
  }
}
