import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const WebViewExampleApp());
}

class WebViewExampleApp extends StatelessWidget {
  const WebViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF334155))),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => WebViewPageState();
}

class WebViewPageState extends State<WebViewPage> {
  final TextEditingController urlController = TextEditingController(text: 'https://flutter.dev');
  late final WebViewController controller;

  double progress = 0;
  bool loading = true;
  bool initialized = false;
  String? pageTitle;
  String? jsMessage;
  String? error;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          if (!mounted) {
            return;
          }
          setState(() => jsMessage = message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => loading = true),
          onPageFinished: (String url) => setState(() => loading = false),
          onProgress: (int value) => setState(() => progress = value / 100),
          onWebResourceError: (WebResourceError resourceError) {
            // 只有主文档加载失败才算页面加载失败，子资源失败不影响页面显示
            if (!mounted || resourceError.isForMainFrame != true) {
              return;
            }
            setState(
              () => error = '页面加载失败：${resourceError.description}（${resourceError.errorType?.name ?? 'unknown'}）',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(urlController.text));
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> load(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      setState(() => error = '无效的网址：$url');
      return;
    }
    setState(() => error = null);
    await controller.loadRequest(uri);
  }

  Future<void> readTitle() async {
    try {
      final Object result = await controller.runJavaScriptReturningResult('document.title');
      if (!mounted) {
        return;
      }
      setState(() => pageTitle = result.toString().replaceAll('"', ''));
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '执行 JS 失败: $exception');
    }
  }

  Future<void> injectBridge() async {
    try {
      await controller.runJavaScript("FlutterBridge.postMessage('来自原生注入的脚本 ' + new Date().toLocaleTimeString());");
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '执行 JS 失败: $exception');
    }
  }

  Future<void> goBack() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
    }
  }

  Future<void> goForward() async {
    if (await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  Future<void> toggleJavaScript() async {
    initialized = !initialized;
    await controller.setJavaScriptMode(initialized ? JavaScriptMode.disabled : JavaScriptMode.unrestricted);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
        actions: [
          IconButton(tooltip: '读取页面标题', onPressed: readTitle, icon: const Icon(Icons.title)),
          IconButton(
            tooltip: initialized ? '恢复 JavaScript' : '禁用 JavaScript',
            onPressed: toggleJavaScript,
            icon: Icon(initialized ? Icons.code_off : Icons.code),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: urlController,
                    decoration: const InputDecoration(hintText: '输入网址', isDense: true, border: OutlineInputBorder()),
                    onSubmitted: load,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: goBack, tooltip: '后退', icon: const Icon(Icons.arrow_back)),
                IconButton(onPressed: goForward, tooltip: '前进', icon: const Icon(Icons.arrow_forward)),
                IconButton(onPressed: controller.reload, tooltip: '刷新', icon: const Icon(Icons.refresh)),
                IconButton(onPressed: () => load(urlController.text), tooltip: '跳转', icon: const Icon(Icons.send)),
              ],
            ),
          ),
          if (loading)
            LinearProgressIndicator(value: progress > 0 && progress < 1 ? progress : null)
          else
            const SizedBox(height: 4),
          if (error != null || pageTitle != null || jsMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pageTitle != null) Text('页面标题：$pageTitle', style: theme.textTheme.bodySmall),
                  if (jsMessage != null) Text('JS 通道消息：$jsMessage', style: theme.textTheme.bodySmall),
                  if (error != null)
                    Text(error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                ],
              ),
            ),
          Expanded(child: WebViewWidget(controller: controller)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: injectBridge,
                      icon: const Icon(Icons.bolt),
                      label: const Text('执行 JS 并通过通道回传'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
