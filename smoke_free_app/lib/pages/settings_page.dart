/// 设置页：戒烟开始时间、烟量烟价、通知开关、数据管理、免责声明。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/quit_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// 弹出数字输入对话框，返回解析后的数值（取消返回 null）。
  Future<num?> _inputNumber(
      BuildContext context, String title, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final v = num.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 修改戒烟开始时间（日期 + 时间两步选择）。
  Future<void> _editQuitStart(BuildContext context, QuitState state) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: state.quitStart ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(state.quitStart ?? now),
    );
    if (time == null || !context.mounted) return;
    await state.startQuit(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _clearAll(BuildContext context, QuitState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空全部数据？'),
        content: const Text('戒烟计时、每日记录、设置都会被删除，\n且无法恢复。确定要重新开始吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await state.clearAll();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuitState>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('戒烟开始时间'),
            subtitle: Text(state.quitStart == null
                ? '未设定'
                : '${state.quitStart!.year}年${state.quitStart!.month}月${state.quitStart!.day}日 '
                    '${state.quitStart!.hour.toString().padLeft(2, '0')}:${state.quitStart!.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editQuitStart(context, state),
          ),
          ListTile(
            leading: const Icon(Icons.smoking_rooms),
            title: const Text('戒烟前每天抽几支'),
            subtitle: Text('${state.cigPerDay} 支（用于计算省钱）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final v = await _inputNumber(
                  context, '每天抽几支？', '${state.cigPerDay}');
              if (v != null && v > 0) {
                await state.updateParams(newCigPerDay: v.toInt());
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('香烟单价（每包）'),
            subtitle: Text('¥${state.packPrice.toStringAsFixed(1)} / 包'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final v = await _inputNumber(
                  context, '一包多少钱？', state.packPrice.toStringAsFixed(1));
              if (v != null && v > 0) {
                await state.updateParams(newPackPrice: v.toDouble());
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('每包支数'),
            subtitle: Text('${state.packSize} 支 / 包'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final v = await _inputNumber(
                  context, '每包多少支？', '${state.packSize}');
              if (v != null && v > 0) {
                await state.updateParams(newPackSize: v.toInt());
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('里程碑通知'),
            subtitle: const Text('达成健康里程碑时提醒你（如"已无烟 3 天"）'),
            value: state.notificationsEnabled,
            onChanged: (v) async {
              final ok = await state.setNotifications(v);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? (v ? '里程碑通知已开启' : '通知已关闭')
                      : '未获得通知权限，请在系统设置中允许'),
                ));
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('清空数据',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('删除计时、记录与设置，重新开始'),
            onTap: () => _clearAll(context, state),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '免责声明：本 App 为自我管理工具，健康里程碑内容'
              '依据世界卫生组织戒烟收益时间轴整理，不构成医疗建议。'
              '烟龄较长或烟量较大者，建议前往医院戒烟门诊，'
              '在医生指导下配合尼古丁替代疗法等药物辅助，成功率更高。'
              '可拨打 12320 卫生热线咨询。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
