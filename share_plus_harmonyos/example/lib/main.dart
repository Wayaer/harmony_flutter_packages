import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'image_previews.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'SharePlus',
        home: Scaffold(
            appBar: AppBar(title: const Text('SharePlus')),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(24), child: const HomePage())));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String text = '';
  String subject = '';
  String uri = '';
  String fileName = '';
  List<String> imageNames = [];
  List<String> imagePaths = [];

  @override
  Widget build(BuildContext context) {
    return Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Share text',
              hintText: 'Enter some text and/or link to share',
            ),
            onChanged: (String value) => setState(() {
              text = value;
            }),
          ),
          TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Share subject',
                hintText: 'Enter subject to share (optional)',
              ),
              onChanged: (String value) {
                subject = value;
                setState(() {});
              }),
          TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Share uri',
                hintText: 'Enter the uri you want to share',
              ),
              onChanged: (String value) {
                setState(() => uri = value);
              }),
          ImagePreviews(imagePaths, onDelete: _onDeleteImage),
          ElevatedButton(
              onPressed: text.isEmpty && imagePaths.isEmpty
                  ? null
                  : _onShareWithResult,
              child: const Text('Share')),
          ElevatedButton.icon(
              label: const Text('Add image'),
              onPressed: () async {
                const typeGroup = XTypeGroup(
                  label: 'images',
                  extensions: <String>['jpg', 'jpeg', 'png', 'gif'],
                );
                final file =
                    await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                if (file != null) {
                  imagePaths.add(file.path);
                  imageNames.add(file.name);
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add)),
          ElevatedButton(
              onPressed: _onShareXFileFromAssets,
              child: const Text('Share XFile from Assets')),
        ]);
  }

  void _onDeleteImage(int position) {
    imagePaths.removeAt(position);
    imageNames.removeAt(position);
    setState(() {});
  }

  void _onShareWithResult() async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    ShareResult shareResult;
    if (imagePaths.isNotEmpty) {
      final files = <XFile>[];
      for (var i = 0; i < imagePaths.length; i++) {
        files.add(XFile(imagePaths[i], name: imageNames[i]));
      }
      shareResult = await SharePlus.instance.share(ShareParams(
        files: files,
        text: text,
        subject: subject,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ));
    } else if (uri.isNotEmpty) {
      shareResult = await SharePlus.instance.share(ShareParams(
        uri: Uri.parse(uri),
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ));
    } else {
      shareResult = await SharePlus.instance.share(ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ));
    }
    scaffoldMessenger.showSnackBar(getResultSnackBar(shareResult));
  }

  void _onShareXFileFromAssets() async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final data = await rootBundle.load('assets/flutter_logo.png');
    final buffer = data.buffer;
    final shareResult = await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(
          buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          name: 'flutter_logo.png',
          mimeType: 'image/png',
        ),
      ],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    ));

    scaffoldMessenger.showSnackBar(getResultSnackBar(shareResult));
  }


  SnackBar getResultSnackBar(ShareResult result) {
    return SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Share result: ${result.status}"),
          if (result.status == ShareResultStatus.success)
            Text("Shared to: ${result.raw}")
        ],
      ),
    );
  }
}
