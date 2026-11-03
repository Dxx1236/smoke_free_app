/// 每日吸烟记录模型（复吸监控的核心数据）。
/// 每天一条：当天共抽了几支。0 支 = 这天守住了。

class DailyLog {
  /// 日期键，格式 yyyy-MM-dd（本地时区）
  final String date;

  /// 当天抽的烟的支数（0 表示全天无烟）
  int cigarettes;

  DailyLog({required this.date, this.cigarettes = 0});

  Map<String, Object?> toMap() => {'date': date, 'cigarettes': cigarettes};

  factory DailyLog.fromMap(Map<String, Object?> map) => DailyLog(
        date: map['date'] as String,
        cigarettes: (map['cigarettes'] as int?) ?? 0,
      );
}

/// 把 DateTime 转成 yyyy-MM-dd 的日期键（本地时区）。
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
