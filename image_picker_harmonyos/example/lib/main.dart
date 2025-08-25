import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Image Picker',
        home: Scaffold(
            appBar: AppBar(title: Text('Image Picker')),
            body: SafeArea(child: HomePage())));
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker picker = ImagePicker();

  List<XFile> files = [];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Wrap(children: [
        Button(
            text: 'Pick Image (Gallery)',
            onTap: () async {
              final result =
                  await picker.pickImage(source: ImageSource.gallery);
              if (result == null) return;
              files.add(result);
              setState(() {});
            }),
        Button(
            text: 'Pick Multi Image',
            onTap: () async {
              final result = await picker.pickMultiImage(limit: 3);
              if (result.isEmpty) return;
              files.addAll(result);
              setState(() {});
            }),
        Button(
            text: 'Pick Image (Camera)',
            onTap: () async {
              final result = await picker.pickImage(source: ImageSource.camera);
              if (result == null) return;
              files.add(result);
              setState(() {});
            }),
        Button(
            text: 'Pick Video (Gallery)',
            onTap: () async {
              final result =
                  await picker.pickVideo(source: ImageSource.gallery);
              if (result == null) return;
              files.add(result);
              setState(() {});
            }),
        Button(
            text: 'Pick Multi Video',
            onTap: () async {
              final result = await picker.pickMultiVideo(limit: 3);
              if (result.isEmpty) return;
              files.addAll(result);
              setState(() {});
            }),
        Button(
            text: 'Pick Video (Camera)',
            onTap: () async {
              final result = await picker.pickVideo(source: ImageSource.camera);
              if (result == null) return;
              files.add(result);
              setState(() {});
            }),
        Button(
            text: 'Pick Media ',
            onTap: () async {
              final result = await picker.pickMedia();
              if (result == null) return;
              files.add(result);
              setState(() {});
            }),
        Button(
            text: 'Pick Multi Media',
            onTap: () async {
              final result = await picker.pickMultipleMedia(limit: 3);
              if (result.isEmpty) return;
              files.addAll(result);
              setState(() {});
            }),
      ]),
      Divider(),
      Expanded(
          child: ListView.separated(
              reverse: true,
              padding: EdgeInsets.all(12),
              itemBuilder: (context, index) =>
                  Text(files[index].path, maxLines: 3),
              separatorBuilder: (context, index) => Divider(),
              itemCount: files.length))
    ]);
  }
}

class Button extends StatelessWidget {
  const Button({super.key, this.text, this.onTap});

  final String? text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onTap, child: Text(text ?? '', textAlign: TextAlign.center));
  }
}