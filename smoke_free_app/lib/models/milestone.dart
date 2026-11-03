/// 健康里程碑模型。
/// 数据来源：世界卫生组织（WHO）戒烟收益时间轴，
/// 经科普中国、香港卫生署、澳门卫生局等权威渠道交叉核对。

class Milestone {
  /// 从戒烟开始时刻算起的时间偏移
  final Duration offset;

  /// 里程碑名称，如 "24小时"
  final String title;

  /// 一句话的人话描述（列表/首页展示用）
  final String shortDesc;

  /// 详细说明（成就页点击展开时展示）
  final String detail;

  const Milestone({
    required this.offset,
    required this.title,
    required this.shortDesc,
    required this.detail,
  });
}

/// 全部里程碑，按时间先后排序。
/// 判断是否解锁：now - quitStart >= offset。
const List<Milestone> kMilestones = [
  Milestone(
    offset: Duration(minutes: 20),
    title: '20分钟',
    shortDesc: '心率和血压开始下降',
    detail: '停止吸烟仅 20 分钟后，因尼古丁而升高的心率和血压就开始回落，'
        '向正常水平恢复。你的身体比想象中恢复得更快。',
  ),
  Milestone(
    offset: Duration(hours: 12),
    title: '12小时',
    shortDesc: '血液中一氧化碳降至正常水平',
    detail: '香烟燃烧产生的一氧化碳会挤占红细胞携氧能力。12 小时后，'
        '你血液中的一氧化碳浓度已降至正常，血液携氧能力恢复。',
  ),
  Milestone(
    offset: Duration(hours: 24),
    title: '24小时',
    shortDesc: '尼古丁基本排空，心脏病发作风险开始下降',
    detail: '一天不吸，血液中的尼古丁已微不足道，心脏病发作的风险开始下降。'
        '注意：这时可能出现烦躁、注意力不集中等戒断反应——这是身体在自我修复，'
        '通常几天内就会缓解，撑过去就是胜利。',
  ),
  Milestone(
    offset: Duration(hours: 72),
    title: '72小时',
    shortDesc: '呼吸更顺畅，味觉嗅觉开始恢复',
    detail: '三天后，支气管开始放松，呼吸会感觉更轻松；'
        '被焦油麻木的味觉和嗅觉神经开始苏醒——你会发现饭菜突然变香了。',
  ),
  Milestone(
    offset: Duration(days: 14),
    title: '2周',
    shortDesc: '血液循环改善，肺功能提升',
    detail: '两周后，全身的血液循环明显改善，走路、爬楼梯不再那么容易喘，'
        '肺功能开始回升（研究显示可达 30% 的提升）。',
  ),
  Milestone(
    offset: Duration(days: 30),
    title: '1个月',
    shortDesc: '咳嗽气短明显减少，气管纤毛重新长出',
    detail: '一个月后，气管和支气管里负责清扫粘液的纤毛重新长出，'
        '肺部自洁能力恢复，咳嗽和气短明显减少，肺部感染风险显著下降。',
  ),
  Milestone(
    offset: Duration(days: 90),
    title: '3个月',
    shortDesc: '肺功能显著提升，戒断反应基本消失',
    detail: '三个月后，肺功能较吸烟期显著提升，大部分戒断症状已经消失，'
        '你会感觉精力比戒烟前明显变好。',
  ),
  Milestone(
    offset: Duration(days: 270),
    title: '9个月',
    shortDesc: '肺部感染风险显著降低',
    detail: '九个月后，肺部纤毛功能完全恢复，清理粘液的能力大幅增强，'
        '支气管炎和肺部感染的风险显著降低。',
  ),
  Milestone(
    offset: Duration(days: 365),
    title: '1年',
    shortDesc: '冠心病风险降至吸烟者的一半',
    detail: '戒烟满一年，因吸烟而增加的冠心病死亡风险降低一半。'
        '这是你送给心脏最贵的一份礼物。',
  ),
  Milestone(
    offset: Duration(days: 365 * 5),
    title: '5年',
    shortDesc: '中风风险接近不吸烟者，口腔癌喉癌食道癌风险减半',
    detail: '戒烟 5 到 15 年后，中风风险降至与不吸烟者相当；'
        '5 年时，口腔癌、喉癌、食道癌的风险也降低了一半。',
  ),
  Milestone(
    offset: Duration(days: 365 * 10),
    title: '10年',
    shortDesc: '肺癌死亡风险降至吸烟者的一半左右',
    detail: '十年后，因肺癌死亡的风险降至继续吸烟者的一半左右，'
        '口腔、喉、食道、膀胱、宫颈和胰腺癌的风险同样显著下降。',
  ),
  Milestone(
    offset: Duration(days: 365 * 15),
    title: '15年',
    shortDesc: '冠心病风险与从不吸烟者相同',
    detail: '十五年后，你的冠心病风险已经和从不吸烟的人完全一样——'
        '从医学意义上说，你的心脏已经"忘了"你曾经吸过烟。',
  ),
];
