/// 本地通知服务：戒烟里程碑达成时推送提醒。
/// 全部为本地通知，不需要服务器。

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/milestone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 初始化插件（App 启动时调用一次）。
  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // 权限在用户打开开关时再申请
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 申请 iOS 通知权限，返回是否获准。
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  /// 为所有"未来的里程碑"安排本地通知。
  /// 每次设置变化（开始时间改动）时先 cancelAll 再重排。
  Future<void> scheduleMilestones(DateTime quitStart) async {
    await cancelAll();
    final location = tz.getLocation('Asia/Shanghai');
    final now = DateTime.now();
    for (var i = 0; i < kMilestones.length; i++) {
      final m = kMilestones[i];
      final at = quitStart.add(m.offset);
      if (at.isBefore(now)) continue; // 已达成的不发
      await _plugin.zonedSchedule(
        i + 100, // 通知 id，里程碑索引 + 100，避免与其他通知冲突
        '戒烟里程碑达成 🎉',
        '你已无烟 ${m.title}：${m.shortDesc}',
        tz.TZDateTime.from(at, location),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'milestone_channel',
            '戒烟里程碑提醒',
            channelDescription: '达成健康里程碑时提醒你',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// 取消全部已安排的通知。
  Future<void> cancelAll() => _plugin.cancelAll();
}
