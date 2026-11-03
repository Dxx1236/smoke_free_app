/// 记录页：复吸监控。
/// 回答三个问题：① 每天抽了几支？② 戒烟后多久开始复吸？③ 每天有没有在减少？
/// 文案原则：不出现"失败""破功"，统一叫"失误""这次没撑住"。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_log.dart';
import '../providers/quit_state.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuitState>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的记录')),
      body: state.quitStart == null
          ? const Center(child: Text('先在首页设定戒烟开始时间'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _relapseStatCard(state),
                const SizedBox(height: 12),
                _trendCard(state),
                const SizedBox(height: 12),
                _barChart(state),
                const SizedBox(height: 16),
                Text('每日明细（点 + / - 修正当天支数）',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                ..._dailyRows(context, state),
              ],
            ),
    );
  }

  /// ① 复吸统计卡：坚持率 + 首次复吸发生在戒烟后多久。
  Widget _relapseStatCard(QuitState state) {
    final t = state.timeToFirstRelapse;
    final relapseText = t == null
        ? '还没有复吸记录，太棒了，继续保持 🎉'
        : '戒烟后 ${state.durationShort(t)} 迎来第一次复吸——\n这很正常，多数人都要经历几次。你已经比上次走得更远。';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.query_stats, size: 28),
                const SizedBox(width: 8),
                Text('坚持率 ${(state.persistRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${state.totalDays} 天里',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            const Divider(height: 24),
            Text('第一次复吸', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(relapseText, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  /// ② 趋势卡：每天有没有在减少。
  Widget _trendCard(QuitState state) {
    final recent = state.recentAvg;
    final prev = state.previousAvg;
    String text;
    IconData icon;
    Color color;
    if (state.trend == 'down') {
      icon = Icons.trending_down;
      color = Colors.green;
      text = '近 7 天平均每天 ${recent.toStringAsFixed(1)} 支，比前 7 天少了 ${(prev - recent).toStringAsFixed(1)} 支——在变好，继续保持 👍';
    } else if (state.trend == 'up') {
      icon = Icons.trending_up;
      color = Colors.deepOrange;
      text = '近 7 天平均每天 ${recent.toStringAsFixed(1)} 支，比前 7 天多了 ${(recent - prev).toStringAsFixed(1)} 支。没关系，看到趋势就是改变的开始。';
    } else {
      icon = Icons.trending_flat;
      color = Colors.blueGrey;
      text = '近 7 天平均每天 ${recent.toStringAsFixed(1)} 支，与前 7 天基本持平。';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  /// ③ 近 14 天吸烟支数柱状图（纯 Flutter 绘制，无第三方图表库）。
  Widget _barChart(QuitState state) {
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.subtract(Duration(days: 13 - i)));
    final counts = days.map((d) => state.cigOn(d)).toList();
    final maxCount = counts.fold<int>(1, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('近 14 天每天抽了几支',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 14; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (counts[i] > 0)
                              Text('${counts[i]}',
                                  style: const TextStyle(fontSize: 9)),
                            const SizedBox(height: 2),
                            Container(
                              height: counts[i] == 0
                                  ? 4
                                  : 10 + (100 * counts[i] / maxCount),
                              decoration: BoxDecoration(
                                color: counts[i] == 0
                                    ? Colors.green.shade400
                                    : Colors.deepOrange.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < 14; i++)
                  Expanded(
                    child: Text(
                      '${days[i].month}/${days[i].day}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 8, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 10, height: 10, color: Colors.green.shade400),
                const SizedBox(width: 4),
                const Text('0 支（守住）', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 16),
                Container(
                    width: 10, height: 10, color: Colors.deepOrange.shade300),
                const SizedBox(width: 4),
                const Text('有吸烟', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ④ 每日明细行（从今天倒序回戒烟日，最多显示 60 天）。
  List<Widget> _dailyRows(BuildContext context, QuitState state) {
    final rows = <Widget>[];
    final today = DateTime.now();
    final total = state.totalDays.clamp(1, 60);
    for (var i = 0; i < total; i++) {
      final d = today.subtract(Duration(days: i));
      final key = dateKey(d);
      final n = state.cigOn(d);
      rows.add(Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            n == 0 ? Icons.check_circle : Icons.warning_amber_rounded,
            color: n == 0 ? Colors.green : Colors.deepOrange,
          ),
          title: Text(
            i == 0
                ? '今天'
                : i == 1
                    ? '昨天'
                    : '${d.month}月${d.day}日',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
              n == 0 ? '守住了 ✓' : (n == 1 ? '抽了 1 支' : '抽了 $n 支'),
              style: TextStyle(
                  color: n == 0 ? Colors.green : Colors.deepOrange,
                  fontSize: 13)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: '减少一支',
                onPressed: n == 0
                    ? null
                    : () => state.setCigarettes(key, n - 1),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: '补记一支（忘了当场记时用）',
                onPressed: () => state.addCigarettes(1, at: d),
              ),
            ],
          ),
        ),
      ));
    }
    return rows;
  }
}
