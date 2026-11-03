/// 本地存储服务。
/// - 设置类数据（戒烟开始时间、烟价等）→ SharedPreferences
/// - 每日吸烟记录 → SQLite（sqflite）
/// 全部数据只存在手机本地，App 完全离线可用。

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Database? _db;

  /// 初始化数据库。幂等，可重复调用。
  Future<void> init() async {
    if (_db != null) return;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'smoke_free.db'),
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE daily_logs('
        'date TEXT PRIMARY KEY, '
        'cigarettes INTEGER NOT NULL DEFAULT 0)',
      ),
    );
  }

  // ---------- 设置（SharedPreferences） ----------

  Future<void> setQuitStart(DateTime t) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('quitStartMs', t.millisecondsSinceEpoch);
  }

  Future<DateTime?> getQuitStart() async {
    final sp = await SharedPreferences.getInstance();
    final ms = sp.getInt('quitStartMs');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<int> getCigPerDay() async =>
      (await SharedPreferences.getInstance()).getInt('cigPerDay') ?? 20;

  Future<void> setCigPerDay(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('cigPerDay', v);
  }

  Future<double> getPackPrice() async =>
      (await SharedPreferences.getInstance()).getDouble('packPrice') ?? 20.0;

  Future<void> setPackPrice(double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble('packPrice', v);
  }

  Future<int> getPackSize() async =>
      (await SharedPreferences.getInstance()).getInt('packSize') ?? 20;

  Future<void> setPackSize(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('packSize', v);
  }

  Future<DateTime?> getFirstRelapse() async {
    final sp = await SharedPreferences.getInstance();
    final ms = sp.getInt('firstRelapseMs');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setFirstRelapse(DateTime t) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('firstRelapseMs', t.millisecondsSinceEpoch);
  }

  Future<bool> getNotificationsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool('notificationsEnabled') ??
      false;

  Future<void> setNotificationsEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('notificationsEnabled', v);
  }

  // ---------- 每日记录（SQLite） ----------

  /// 写入/覆盖某天的记录。
  Future<void> upsertLog(String date, int cigarettes) async {
    await _db!.insert(
      'daily_logs',
      {'date': date, 'cigarettes': cigarettes},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 读取全部每日记录，返回 {日期: 支数}。
  Future<Map<String, int>> loadAllLogs() async {
    final rows = await _db!.query('daily_logs');
    return {
      for (final r in rows) r['date'] as String: (r['cigarettes'] as int?) ?? 0,
    };
  }

  /// 清空全部数据（设置 + 记录）。
  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    await _db!.delete('daily_logs');
  }
}
