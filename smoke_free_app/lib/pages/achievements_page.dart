/// 成就页：健康收益时间轴。
/// 每个节点 = 一个身体恢复里程碑；已解锁金色，未解锁灰色并显示还差多久。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/milestone.dart';
import '../providers/quit_state.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  /// 剩余时间 → "还差 3 天" 的文本。
  String _remaining(Duration gap) {
    if (gap.inDays >= 1) return '还差 ${gap.inDays} 天';
    if (gap.inHours >= 1) return '还差 ${gap.inHours} 小时';
    return '还差 ${gap.inMinutes} 分钟';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuitState>();

    return Scaffold(
      appBar: AppBar(title: const Text('你已经赚到了什么')),
      body: state.quitStart == null
          ? const Center(child: Text('先在首页设定戒烟开始时间'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: kMilestones.length + 2, // 头部统计 + 里程碑们 + 尾部目标
              itemBuilder: (context, i) {
                if (i == 0) return _header(state);
                if (i == kMilestones.length + 1) return _footer(state);
                final m = kMilestones[i - 1];
                return _timelineNode(context, state, m);
              },
            ),
    );
  }

  /// 顶部进度统计。
  Widget _header(QuitState state) {
    final unlocked = state.unlockedMilestones.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.health_and_safety_outlined, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已解锁 $unlocked / ${kMilestones.length} 个健康里程碑',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('数据依据世界卫生组织戒烟收益时间轴，由身体机制决定，只要不抽就一定会发生。',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单个时间轴节点。
  Widget _timelineNode(BuildContext context, QuitState state, Milestone m) {
    final unlocked = state.elapsed >= m.offset;
    final color = unlocked ? const Color(0xFFF9A825) : Colors.grey.shade400;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧：圆点 + 连接线
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Icon(
                  unlocked ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: color,
                  size: 26,
                ),
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右侧：卡片
          Expanded(
            child: GestureDetector(
              onTap: () => _showDetail(context, m, unlocked),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: unlocked ? Colors.amber.shade50 : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(m.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: unlocked
                                      ? const Color(0xFFB28704)
                                      : Colors.grey.shade700)),
                          const Spacer(),
                          Text(
                            unlocked ? '✓ 已解锁' : _remaining(m.offset - state.elapsed),
                            style: TextStyle(
                                fontSize: 12,
                                color: unlocked
                                    ? const Color(0xFFB28704)
                                    : Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(m.shortDesc,
                          style: const TextStyle(fontSize: 14, height: 1.4)),
                      if (!unlocked)
                        Text('点按查看详情',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 点击展开的详情弹窗。
  void _showDetail(BuildContext context, Milestone m, bool unlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${m.title} · ${m.shortDesc}'),
        content: Text(m.detail, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(unlocked ? '真棒' : '收到，继续熬'),
          ),
        ],
      ),
    );
  }

  /// 底部：下一个远期目标。
  Widget _footer(QuitState state) {
    final next = state.nextMilestone;
    if (next == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('🏆 全部里程碑已解锁，你就是活教材！')),
      );
    }
    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '下一站：${next.title} · ${next.shortDesc}\n还差 ${_remaining(next.offset - state.elapsed)}，一步一步来。',
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
