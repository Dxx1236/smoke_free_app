/// 首页：戒烟计时 + 今日状态 + 省钱 + 已解锁里程碑速览 + 烟瘾急救入口。
/// 右下角红色的"烟瘾来了"悬浮大按钮是全 App 最重要的入口。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/quit_state.dart';
import 'settings_page.dart';
import 'sos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer; // 每秒刷新计时文本

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // 计时是"开始时间 + 时间差"，App 被杀也永远不会算错
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// "今天没抽"打卡：根据当天实际记录给出反馈。
  void _markClean(QuitState state) {
    if (state.todayCigs == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('第 ${state.totalDays} 天守住了，了不起 👏')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今天已有复吸记录。没关系，下一支不抽就是新的开始。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuitState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我已无烟'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      // ⑥ 全 App 最重要的按钮：烟瘾急救
      floatingActionButton: state.quitStart == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SosPage()),
              ),
              backgroundColor: const Color(0xFFD84315),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.emergency),
              label: const Text('烟瘾来了，救我',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
      body: state.quitStart == null
          ? _OnboardingView()
          : _HomeBody(state: state, cs: cs, onMarkClean: () => _markClean(state)),
    );
  }
}

/// 首次使用的引导：设定戒烟开始时刻。
class _OnboardingView extends StatelessWidget {
  Future<void> _pick(BuildContext context, QuitState state) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !context.mounted) return;
    await state.startQuit(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开始了。从这一刻起，每 20 分钟你都在变好。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuitState>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smoke_free, size: 96, color: Color(0xFF00897B)),
            const SizedBox(height: 24),
            const Text('熬过去',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '烟瘾发作时，那股劲儿通常 5~15 分钟\n就会自己过去。你要做的只是熬过它。',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => _pick(context, state),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('设定戒烟开始时间', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            Text('建议选择一个轻松的日子正式开始（如周末早晨）',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final QuitState state;
  final ColorScheme cs;
  final VoidCallback onMarkClean;

  const _HomeBody({
    required this.state,
    required this.cs,
    required this.onMarkClean,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        // ① 大数字计时
        Center(
          child: Column(
            children: [
              Text(
                state.elapsedText(),
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text('从 ${_fmt(state.quitStart!)} 开始，每一秒都在变好',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ② 今日状态
        Card(
          child: ListTile(
            leading: Icon(
              state.todayClean
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: state.todayClean ? Colors.green : Colors.grey,
              size: 32,
            ),
            title: Text(
              state.todayClean ? '今天守住了，已无烟' : '今天还没抽烟',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('今天是第 ${state.totalDays} 天 · 坚持率 ${(state.persistRate * 100).toStringAsFixed(0)}%'),
            trailing: state.todayClean
                ? null
                : TextButton(onPressed: onMarkClean, child: const Text('今天没抽 ✓')),
          ),
        ),
        const SizedBox(height: 12),

        // ③ 省下的钱
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, size: 36),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已省下 ¥${state.moneySaved.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(state.moneyRewardText(),
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ④ 已解锁里程碑（横向卡片，最新解锁的排最前）
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('已解锁 ${state.unlockedMilestones.length}/12',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('「成就」页可查看全部',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: state.unlockedMilestones.isEmpty
              ? Card(
                  child: Center(
                    child: Text('第一个里程碑：无烟 20 分钟\n马上就到',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.unlockedMilestones.length,
                  reverse: true,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final m = state.unlockedMilestones[
                        state.unlockedMilestones.length - 1 - i];
                    return SizedBox(
                      width: 200,
                      child: Card(
                        color: Colors.amber.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✓ 已达成',
                                  style: TextStyle(
                                      color: Color(0xFFF9A825), fontSize: 12)),
                              Text(m.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(m.shortDesc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

String _fmt(DateTime t) =>
    '${t.year}年${t.month}月${t.day}日 ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
