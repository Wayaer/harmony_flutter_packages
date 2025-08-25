import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SharedPreferences',
      home: Scaffold(
          appBar: AppBar(title: const Text('SharedPreferences')),
          body: SharedPreferencesDemo()),
    );
  }
}

class SharedPreferencesDemo extends StatefulWidget {
  const SharedPreferencesDemo({super.key});

  @override
  SharedPreferencesDemoState createState() => SharedPreferencesDemoState();
}

class SharedPreferencesDemoState extends State<SharedPreferencesDemo> {
  String text = '';
  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _sharedPreferences = await SharedPreferences.getInstance();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return _sharedPreferences == null
        ? const Center(child: CircularProgressIndicator())
        : buildContent;
  }

  Widget get buildContent => Column(children: [
        Container(
          margin: const EdgeInsets.all(12),
          height: 120,
          child: Card(
              margin: const EdgeInsets.all(12),
              child: Center(child: Text(text))),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              text: 'setString',
              onTap: () {
                _sharedPreferences
                    ?.setString('String Key', 'String value')
                    .then((
                  value,
                ) {
                  text = 'call setString() result: $value';
                  setState(() {});
                });
              },
            ),
            const SizedBox(width: 20),
            Button(
              text: 'getString',
              onTap: () {
                final value = _sharedPreferences?.getString('String Key');
                text = 'call getString() result: $value';
                setState(() {});
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              text: 'setBool',
              onTap: () {
                _sharedPreferences?.setBool('bool Key', true).then((value) {
                  text = 'call setBool() result: $value';
                  setState(() {});
                });
              },
            ),
            const SizedBox(width: 20),
            Button(
              text: 'getBool',
              onTap: () {
                final value = _sharedPreferences?.getBool('bool Key');
                text = 'call getBool() result: $value';
                setState(() {});
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              text: 'setDouble',
              onTap: () {
                _sharedPreferences?.setDouble('double Key', 2.33).then((value) {
                  text = 'call setDouble() result: $value';
                  setState(() {});
                });
              },
            ),
            const SizedBox(width: 20),
            Button(
              text: 'getDouble',
              onTap: () {
                final value = _sharedPreferences?.getDouble('double Key');
                text = 'call getDouble() result: $value';
                setState(() {});
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              text: 'setInt',
              onTap: () {
                _sharedPreferences?.setInt('int Key', 233).then((value) {
                  text = 'call setInt() result: $value';
                  setState(() {});
                });
              },
            ),
            const SizedBox(width: 20),
            Button(
              text: 'getInt',
              onTap: () {
                final value = _sharedPreferences?.getInt('int Key');
                text = 'call getInt() result: $value';
                setState(() {});
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              text: 'setStringList',
              onTap: () {
                _sharedPreferences?.setStringList(
                    'list<String> Key', ['1', '2', '3']).then((value) {
                  text = 'call setStringList() result: $value';
                  setState(() {});
                });
              },
            ),
            const SizedBox(width: 20),
            Button(
              text: 'getStringList',
              onTap: () {
                final value = _sharedPreferences?.getStringList(
                  'list<String> Key',
                );
                text = 'call getStringList() result: $value';
                setState(() {});
              },
            ),
          ],
        ),
      ]);
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