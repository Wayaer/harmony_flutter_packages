import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Path Provider',
        home: Scaffold(
            appBar: AppBar(title: Text('Path Provider')), body: HomePage()));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, List<Directory>> _directories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getDirectories();
    });
  }

  void getDirectories() async {
    final temp = await getTemporaryDirectory();
    _directories.addAll({
      'getTemporaryDirectory': [temp]
    });
    final appSupport = await getApplicationSupportDirectory();
    _directories.addAll({
      'getApplicationSupportDirectory': [appSupport]
    });
    final appDocuments = await getApplicationDocumentsDirectory();
    _directories.addAll({
      'getApplicationDocumentsDirectory': [appDocuments]
    });
    final appCache = await getApplicationCacheDirectory();
    _directories.addAll({
      'getApplicationCacheDirectory': [appCache]
    });
    final externalDocuments = await getExternalStorageDirectory();
    _directories.addAll({
      'getExternalStorageDirectory':
          externalDocuments == null ? [] : [externalDocuments]
    });
    final downloads = await getDownloadsDirectory();
    _directories.addAll({
      'getDownloadsDirectory': downloads == null ? [] : [downloads]
    });
    final externalCache = await getExternalCacheDirectories();
    _directories.addAll({'getExternalCacheDirectories': externalCache ?? []});
    final externalStorage = await getExternalStorageDirectories();
    _directories
        .addAll({'getExternalStorageDirectories': externalStorage ?? []});
    for (final value in StorageDirectory.values) {
      final directories = await getExternalStorageDirectories(type: value);
      _directories
          .addAll({'getExternalStorageDirectories $value': directories ?? []});
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: _directories.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Text(e.key,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...e.value.map((e) => Text(e.path)),
                      ]),
                ))
            .toList());
  }
}
