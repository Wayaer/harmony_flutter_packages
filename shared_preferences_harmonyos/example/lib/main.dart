import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_harmonyos/shared_preferences_harmonyos.dart';

void main() {
  runApp(const SharedPreferencesExampleApp());
}

class SharedPreferencesExampleApp extends StatelessWidget {
  const SharedPreferencesExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Preferences',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5))),
      home: const PreferencesPage(),
    );
  }
}

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => PreferencesPageState();
}

class PreferencesPageState extends State<PreferencesPage> {
  static const String counterKey = 'demo_counter';
  static const String textKey = 'demo_text';
  static const String listKey = 'demo_list';
  static const String asyncKey = 'demo_async_text';

  static const String defaultText = '来自 Flutter 鸿蒙插件的示例文本';
  static const List<String> defaultList = <String>['示例一', '示例二', '示例三'];
  static const String defaultAsyncText = '异步存储的示例值';

  final TextEditingController textController = TextEditingController();
  final SharedPreferencesAsync asyncPreferences = SharedPreferencesAsync(
    options: const SharedPreferencesAsyncOhosOptions(),
  );

  SharedPreferences? preferences;
  int counter = 0;
  String? text;
  List<String> list = <String>[];
  String? asyncText;
  Map<String, Object?> allValues = <String, Object?>{};
  String? error;

  /// 只在首次加载时写入默认值，避免用户清空后刷新又自动恢复。
  bool seeded = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (!seeded) {
        seeded = true;
        await seedDefaults(prefs);
      }
      final int counterValue = prefs.getInt(counterKey) ?? 0;
      final String? textValue = prefs.getString(textKey);
      final List<String> listValue = prefs.getStringList(listKey) ?? <String>[];
      final String? asyncValue = await asyncPreferences.getString(asyncKey);
      final Map<String, Object?> values = <String, Object?>{
        for (final String key in prefs.getKeys()) key: prefs.get(key),
      };
      if (!mounted) {
        return;
      }
      setState(() {
        preferences = prefs;
        counter = counterValue;
        text = textValue;
        list = listValue;
        asyncText = asyncValue;
        allValues = values;
        error = null;
        textController.text = textValue ?? defaultText;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '读取失败: $exception');
    }
  }

  Future<void> seedDefaults(SharedPreferences prefs) async {
    if (!prefs.containsKey(textKey)) {
      await prefs.setString(textKey, defaultText);
    }
    if (!prefs.containsKey(listKey)) {
      await prefs.setStringList(listKey, defaultList);
    }
    if (!await asyncPreferences.containsKey(asyncKey)) {
      await asyncPreferences.setString(asyncKey, defaultAsyncText);
    }
  }

  Future<void> run(Future<void> Function(SharedPreferences prefs) action) async {
    final SharedPreferences? prefs = preferences;
    if (prefs == null) {
      return;
    }
    try {
      await action(prefs);
      await load();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '操作失败: $exception');
    }
  }

  Future<void> incrementCounter() => run((SharedPreferences prefs) => prefs.setInt(counterKey, counter + 1));

  Future<void> resetCounter() => run((SharedPreferences prefs) => prefs.setInt(counterKey, 0));

  Future<void> saveText() => run((SharedPreferences prefs) => prefs.setString(textKey, textController.text));

  Future<void> removeText() => run((SharedPreferences prefs) => prefs.remove(textKey));

  Future<void> addListItem() => run((SharedPreferences prefs) {
    final List<String> items = <String>[...list, '${list.length + 1}. ${DateTime.now().second} 秒'];
    return prefs.setStringList(listKey, items);
  });

  Future<void> clearList() => run((SharedPreferences prefs) => prefs.setStringList(listKey, <String>[]));

  Future<void> saveAsyncText() async {
    try {
      await asyncPreferences.setString(asyncKey, textController.text);
      await load();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '异步写入失败: $exception');
    }
  }

  Future<void> removeAsyncText() async {
    try {
      await asyncPreferences.remove(asyncKey);
      await load();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '异步删除失败: $exception');
    }
  }

  Future<void> clearAll() async {
    final SharedPreferences? prefs = preferences;
    if (prefs == null) {
      return;
    }
    try {
      await prefs.clear();
      await asyncPreferences.clear();
      await load();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      setState(() => error = '清空失败: $exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Preferences'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh), tooltip: '重新读取')],
      ),
      body: preferences == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Text(error!, style: TextStyle(color: theme.colorScheme.error)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: '计数器（setInt / getInt）',
                  icon: Icons.exposure_plus_1,
                  child: Row(
                    children: [
                      Text('$counter', style: theme.textTheme.headlineSmall),
                      const Spacer(),
                      OutlinedButton(onPressed: resetCounter, child: const Text('归零')),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: incrementCounter, child: const Text('+1')),
                    ],
                  ),
                ),
                _Section(
                  title: '文本（setString / getString / remove）',
                  icon: Icons.text_fields,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: textController,
                        decoration: const InputDecoration(labelText: '要保存的文本', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(onPressed: saveText, child: const Text('保存')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(onPressed: removeText, child: const Text('删除')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('当前值：${text ?? '空'}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                _Section(
                  title: '字符串列表（setStringList / getStringList）',
                  icon: Icons.list_alt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (list.isEmpty)
                        Text('列表为空', style: theme.textTheme.bodyMedium)
                      else
                        for (final String item in list) Chip(label: Text(item)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(onPressed: addListItem, child: const Text('添加一项')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(onPressed: clearList, child: const Text('清空列表')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '异步 API（SharedPreferencesAsync + DataStore）',
                  icon: Icons.bolt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('当前值：${asyncText ?? '空'}', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(onPressed: saveAsyncText, child: const Text('写入上方文本')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(onPressed: removeAsyncText, child: const Text('删除')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '全部数据（getKeys / get）',
                  icon: Icons.storage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allValues.isEmpty)
                        Text('暂无数据', style: theme.textTheme.bodyMedium)
                      else
                        for (final MapEntry<String, Object?> entry in allValues.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('${entry.key}：${entry.value}', style: theme.textTheme.bodySmall),
                          ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: clearAll,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('clear() 清空全部'),
                      ),
                    ],
                  ),
                ),
                if (error != null) Text(error!, style: TextStyle(color: theme.colorScheme.error)),
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
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
