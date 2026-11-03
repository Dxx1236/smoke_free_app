/// 全局戒烟状态（ChangeNotifier）。
/// 所有页面的数据都从这里读，修改也都走这里，改完自动刷新 UI。

import 'package:flutter/foundation.dart';

import '../models/daily_log.dart';
import '../models/milestone.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class QuitState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  bool loaded = false;

  // ---------- 原始数据 ----------
  DateTime? quitStart; // 戒烟开始时刻（核心！计时永远用它做差值，绝不累加）
  int cigPerDay = 20; // 戒烟前每天抽几支
  double packPrice = 20.0; // 每包价格（元）
  int packSize = 20; // 每包支数
  DateTime? firstRelapse; // 戒烟后第一次复吸的时刻（只记录第一次，作为历史事实）
  Map<String, int> logs = {}; // {yyyy-MM-dd: 当天吸烟支数}
  bool notificationsEnabled = false;

  // ---------- 初始化 ----------
  Future<void> load() async {
    await _storage.init();
    quitStart = await _storage.getQuitStart();
    cigPerDay = await _storage.getCigPerDay();
    packPrice = await _storage.getPackPrice();
    packSize = await _storage.getPackSize();
    firstRelapse = await _storage.getFirstRelapse();
    notificationsEnabled = await _storage.getNotificationsEnabled();
    logs = await _storage.loadAllLogs();
    loaded = true;
    notifyListeners();
  }

  // ---------- 写操作 ----------

  /// 设定戒烟开始时间（首次使用或重新开始时调用）。
  /// 不清零历史记录——之前的努力依然保留在记录页里。
  Future<void> startQuit(DateTime at) async {
    quitStart = at;
    await _storage.setQuitStart(at);
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleMilestones(at);
    }
    notifyListeners();
  }

  /// 记一支烟（复吸记录，永不清零计时）。
  Future<void> addCigarettes(int n, {DateTime? at}) async {
    final t = at ?? DateTime.now();
    final key = dateKey(t);
    logs[key] = (logs[key] ?? 0) + n;
    await _storage.upsertLog(key, logs[key]!);
    // 只记第一次复吸的时间点（多久开始复吸）
    firstRelapse ??= t;
    await _storage.setFirstRelapse(firstRelapse!);
    notifyListeners();
  }

  /// 修正某天的支数（记录页 + / - 用），最小为 0。
  Future<void> setCigarettes(String date, int n) async {
    logs[date] = n < 0 ? 0 : n;
    await _storage.upsertLog(date, logs[date]!);
    notifyListeners();
  }

  /// 更新烟量/烟价等参数。
  Future<void> updateParams({
    int? newCigPerDay,
    double? newPackPrice,
    int? newPackSize,
  }) async {
    if (newCigPerDay != null) {
      cigPerDay = newCigPerDay;
      await _storage.setCigPerDay(cigPerDay);
    }
    if (newPackPrice != null) {
      packPrice = newPackPrice;
      await _storage.setPackPrice(packPrice);
    }
    if (newPackSize != null) {
      packSize = newPackSize;
      await _storage.setPackSize(packSize);
    }
    notifyListeners();
  }

  /// 开关里程碑通知。
  Future<bool> setNotifications(bool enabled) async {
    if (enabled && quitStart == null) return false;
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return false;
      await NotificationService.instance
          .scheduleMilestones(quitStart!);
    } else {
      await NotificationService.instance.cancelAll();
    }
    notificationsEnabled = enabled;
    await _storage.setNotificationsEnabled(enabled);
    notifyListeners();
    return true;
  }

  /// 清空全部数据并重置（设置页"清空数据"用）。
  Future<void> clearAll() async {
    await NotificationService.instance.cancelAll();
    await _storage.clearAll();
    quitStart = null;
    firstRelapse = null;
    notificationsEnabled = false;
    logs = {};
    notifyListeners();
  }

  // ---------- 派生数据（全部实时计算） ----------

  /// 已无烟时长。
  Duration get elapsed =>
      quitStart == null ? Duration.zero : DateTime.now().difference(quitStart!);

  /// 已省下的钱（按"戒烟前每天花掉的钱"折算）。
  double get moneySaved {
    if (quitStart == null) return 0;
    final days = elapsed.inMinutes / 1440.0;
    final perPackMoney = cigPerDay / packSize * packPrice;
    return days * perPackMoney;
  }

  /// 已达成的里程碑列表。
  List<Milestone> get unlockedMilestones =>
      quitStart == null ? [] : kMilestones.where((m) => elapsed >= m.offset).toList();

  /// 下一个待解锁的里程碑（全部达成则返回 null）。
  Milestone? get nextMilestone {
    for (final m in kMilestones) {
      if (elapsed < m.offset) return m;
    }
    return null;
  }

  /// 某天抽了几支。
  int cigOn(DateTime d) => logs[dateKey(d)] ?? 0;

  /// 今天抽了几支。
  int get todayCigs => cigOn(DateTime.now());

  /// 今天是否守住了（0 支）。
  bool get todayClean => quitStart != null && todayCigs == 0;

  /// 从戒烟日到今天的天数（含当天）。
  int get totalDays {
    if (quitStart == null) return 0;
    final start = DateTime(quitStart!.year, quitStart!.month, quitStart!.day);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).difference(start).inDays + 1;
  }

  /// 坚持率 = 无烟天数 / 总天数（复吸不清零，所以这个数字只涨不跌太多）。
  double get persistRate {
    if (quitStart == null || totalDays <= 0) return 0;
    var cleanDays = 0;
    for (var i = 0; i < totalDays; i++) {
      final d = quitStart!.add(Duration(days: i));
      if (cigOn(d) == 0) cleanDays++;
    }
    return cleanDays / totalDays;
  }

  /// 复吸距戒烟开始多久（首次复吸的"坚持了多久"）。
  Duration? get timeToFirstRelapse => firstRelapse == null || quitStart == null
      ? null
      : firstRelapse!.difference(quitStart!);

  /// 近 7 天日均支数。
  double get recentAvg {
    var sum = 0;
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      sum += cigOn(now.subtract(Duration(days: i)));
    }
    return sum / 7;
  }

  /// 前 7 天（第 8~14 天前）日均支数。
  double get previousAvg {
    var sum = 0;
    final now = DateTime.now();
    for (var i = 7; i < 14; i++) {
      sum += cigOn(now.subtract(Duration(days: i)));
    }
    return sum / 7;
  }

  /// 趋势判断：'down' 在减少 / 'up' 在增加 / 'flat' 持平。
  String get trend {
    final diff = previousAvg - recentAvg;
    if (diff > 0.5) return 'down';
    if (diff < -0.5) return 'up';
    return 'flat';
  }

  // ---------- 格式化工具 ----------

  /// 计时文本：X天 HH:MM:SS。
  String elapsedText() {
    final e = elapsed;
    final d = e.inDays;
    final h = e.inHours % 24;
    final m = e.inMinutes % 60;
    final s = e.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '$d天 ${two(h)}:${two(m)}:${two(s)}';
  }

  /// 时长 → "X天Y小时" 的短描述。
  String durationShort(Duration d) {
    if (d.inDays >= 1) {
      final h = d.inHours % 24;
      return h == 0 ? '${d.inDays}天' : '${d.inDays}天${h}小时';
    }
    if (d.inHours >= 1) return '${d.inHours}小时${d.inMinutes % 60}分钟';
    return '${d.inMinutes}分钟';
  }

  /// 把省下的钱翻译成具体的东西。
  String moneyRewardText() {
    final amount = moneySaved;
    const rewards = [
      ('一杯奶茶', 15.0),
      ('一顿早餐', 25.0),
      ('一场电影', 50.0),
      ('一顿火锅', 150.0),
      ('一双跑鞋', 500.0),
      ('一次周末短途游', 1500.0),
      ('一部新手机', 4000.0),
    ];
    String? best;
    for (final r in rewards) {
      if (amount >= r.$2) best = r.$1;
    }
    if (best == null) return '再坚持一会儿，第一杯奶茶就到手';
    return '≈ $best';
  }
}
