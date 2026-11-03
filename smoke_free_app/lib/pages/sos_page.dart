/// 烟瘾急救页（全 App 的核心页面）。
/// 逻辑：烟瘾通常 5~15 分钟自行消退 → 提供 15 分钟倒计时 + 4 步动作引导，
/// 帮用户把注意力从"想抽"挪到"做动作"上。
/// 没撑住也永远不说"你失败了"——记录支数，继续走。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/quit_state.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  static const _totalSeconds = 15 * 60;

  int _remaining = _totalSeconds;
  int _stepIndex = 0; // 当前进行到第几步
  bool _finished = false; // 15 分钟熬完
  Timer? _timer;

  static const _steps = [
    (
      '深呼吸 3 次',
      '跟着节奏来：吸气 4 秒 → 停住 4 秒 → 缓缓呼气 6 秒。\n重复 3 轮，心率就会慢下来。',
      Icons.air
    ),
    (
      '喝一大杯水',
      '大口喝，慢慢咽。喝水能占据你的嘴和手，\n还能冲淡口腔里的烟味记忆。',
      Icons.local_drink
    ),
    (
      '离开这个环境',
      '站起来，走 100 步，或者去洗把脸。\n烟瘾总是和特定的场景绑在一起，换个地方它就弱了。',
      Icons.directions_walk
    ),
    (
      '告诉自己一句话',
      '"我不是在放弃享受，\n我是在摆脱控制。"\n——念出来，或在心里默念。',
      Icons.favorite
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _finished = true;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 没撑住：记录今天抽的支数（不清零计时）。
  Future<void> _relapsed() async {
    var count = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('记一笔，不怪你'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('戒烟不是一次成功的事。\n记下来，明天比今天少抽一支就是进步。',
                  style: TextStyle(height: 1.5)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: count > 1
                        ? () => setDialog(() => count--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$count 支',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setDialog(() => count++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('再试试'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('记下了，继续走'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await context.read<QuitState>().addCigarettes(count);
      if (!mounted) return;
      Navigator.of(context).pop(); // 回首页
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已记录。计时没有清零——你的努力都还在。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('急救中'),
        centerTitle: true,
      ),
      body: _finished ? _buildWin() : _buildCountdown(cs),
    );
  }

  /// 15 分钟倒计时 + 分步引导。
  Widget _buildCountdown(ColorScheme cs) {
    final step = _steps[_stepIndex];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('这股劲儿，15 分钟就会过去',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          // 倒计时圆环
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _remaining / _totalSeconds,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFFD84315),
                  ),
                ),
                Text(_clock,
                    style: const TextStyle(
                        fontSize: 44, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 当前步骤卡片
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('第 ${_stepIndex + 1} 步 / 共 ${_steps.length} 步',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    Icon(step.$3, size: 56, color: cs.primary),
                    const SizedBox(height: 16),
                    Text(step.$1,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(step.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, height: 1.6)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 下一步 / 完成
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                if (_stepIndex < _steps.length - 1) {
                  setState(() => _stepIndex++);
                } else {
                  setState(() => _stepIndex = 0); // 做完一轮从头再来，直到熬过去
                }
              },
              child: Text(_stepIndex < _steps.length - 1
                  ? '做完了，下一步'
                  : '很好，再来一轮'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _relapsed,
            child: Text('没撑住，我抽了一根',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 熬过 15 分钟后的胜利页。
  Widget _buildWin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 96, color: Color(0xFFF9A825)),
            const SizedBox(height: 24),
            const Text('你赢了这一次 🎉',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '这一次烟瘾已经过去了，\n它还会再来，但你已经知道怎么赢了。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text('返回首页'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
