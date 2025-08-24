import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectivityPlus',
      home: Scaffold(
          appBar: AppBar(title: Text('ConnectivityPlus')),
          body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: HomePage()))),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ConnectivityResult> _connectionStatus = [];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }
    _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
      _connectionStatus = result;
    setState(() {});
    debugPrint('Connectivity changed: $_connectionStatus');
  }

  @override
  Widget build(BuildContext context) {
    return Column(spacing: 20, children: [
      Text('Active connection types:',
          style: Theme.of(context).textTheme.bodyLarge),
      ...List.generate(_connectionStatus.length,
          (index) => Text(_connectionStatus[index].toString()))
    ]);
  }
}
