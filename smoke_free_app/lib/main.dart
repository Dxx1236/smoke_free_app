/// 「熬过去」戒烟助手 - 入口。
/// 架构：页面层(pages/) → 全局状态(providers/) → 存储层(services/)。
/// 完全离线运行，无账号、无网络请求。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/achievements_page.dart';
import 'pages/home_page.dart';
import 'pages/records_page.dart';
import 'providers/quit_state.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init(); // 通知插件初始化
  final quitState = QuitState();
  await quitState.load(); // 启动时读取本地数据
  runApp(SmokeFreeApp(quitState: quitState));
}

class SmokeFreeApp extends StatelessWidget {
  final QuitState quitState;
  const SmokeFreeApp({super.key, required this.quitState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: quitState,
      child: MaterialApp(
        title: '熬过去 · 戒烟助手',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
        ),
        home: const RootPage(),
      ),
    );
  }
}

/// 底部导航壳：首页 / 成就 / 记录 三个 tab。
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  static const _pages = [HomePage(), AchievementsPage(), RecordsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: '成就'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '记录'),
        ],
      ),
    );
  }
}
