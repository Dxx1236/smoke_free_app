# 熬过去 · 戒烟助手（smoke_free_app）

帮你撑过每一次烟瘾发作的 Flutter 戒烟 App。完全离线、无账号、无广告。

## 核心功能（V1）

1. **戒烟计时**：精确到秒；存"开始时间戳 + 实时算差值"，App 被杀、手机重启都不会算错。
2. **健康里程碑时间轴**：20分钟 / 12小时 / 24小时 / 72小时 / 2周 / 1个月 / 3个月 / 9个月 / 1年 / 5年 / 10年 / 15年，全部依据 WHO 戒烟收益时间轴，逐个解锁。
3. **烟瘾急救页**：15 分钟倒计时圆环 + 4 步动作引导（深呼吸 / 喝水 / 离开环境 / 一句话），没撑住可记录支数，**永不清零**。
4. **复吸监控**：每天抽了几支、戒烟后多久开始第一次复吸、近 7 天 vs 前 7 天趋势（在减少吗）、14 天柱状图。
5. **省钱计算**：按烟量烟价折算，并翻译成"≈ 一顿火锅"这样的具体回报。
6. **里程碑本地通知**：未来的里程碑会提前排好，到点推送提醒（需授权通知权限）。

## 项目结构

```
smoke_free_app/
├── pubspec.yaml                     # 依赖清单
├── lib/
│   ├── main.dart                    # 入口 + 底部导航壳（首页/成就/记录）
│   ├── models/
│   │   ├── milestone.dart           # 健康里程碑数据（WHO 时间轴）
│   │   └── daily_log.dart           # 每日吸烟记录模型
│   ├── services/
│   │   ├── storage_service.dart     # SharedPreferences(设置) + SQLite(记录)
│   │   └── notification_service.dart# 本地通知（里程碑提醒）
│   ├── providers/
│   │   └── quit_state.dart          # 全局状态：计时/省钱/坚持率/趋势等全部派生数据
│   └── pages/
│       ├── home_page.dart           # 首页（计时 + 急救大按钮）
│       ├── sos_page.dart            # 烟瘾急救（15分钟倒计时 + 4步引导）
│       ├── achievements_page.dart   # 成就时间轴
│       ├── records_page.dart        # 复吸监控（趋势图 + 每日明细）
│       └── settings_page.dart       # 设置
└── （ios/、android/ 由 flutter create . 自动生成，见下文）
```

## 一、准备环境（需要一台 Mac，或用云端方案，见第三节）

```bash
# 1. 安装 Flutter SDK（https://docs.flutter.dev/get-started/install/macos）
# 2. 安装 Xcode（App Store，需要 macOS）
# 3. 安装 CocoaPods
sudo gem install cocoapods
# 4. 检查环境
flutter doctor
```

## 二、生成工程并运行

本项目交付的是全部源码；`ios/` `android/` 平台目录由 Flutter 官方命令生成：

```bash
cd smoke_free_app
flutter create . --org com.example --project-name smoke_free_app
flutter pub get
flutter run        # 连上 iPhone 或启动模拟器即可真机调试
```

> 如果 `flutter pub get` 报版本冲突，按报错提示把 pubspec.yaml 中对应依赖的版本号放宽（如 `^17.0.0` 改 `any`）再重试。

## 三、打包 IPA（三选一）

### ⚠️ 重要前提
**IPA 只能在 macOS 上用 Xcode 打包。** Windows 电脑无法生成 IPA。三条路线：

### 路线 A：有 Mac（最直接）
```bash
flutter build ipa --release
```
- 需要 **Apple Developer Program 账号（99 美元/年）** 用于签名；
- 产物在 `build/ios/archive/`，用 Xcode 上传 App Store Connect → TestFlight 分发给自己和朋友试用；
- 只想装自己手机、不想花钱：用免费 Apple ID 在 Xcode 里直接 Run 到真机，**签名 7 天过期**，到期重装。

### 路线 B：Codemagic 云端打包（没有 Mac 的推荐方案）
1. 把代码推到 GitHub；
2. 注册 codemagic.io（免费额度每月 500 分钟，Flutter 官方合作 CI）；
3. 选 Flutter 项目 → iOS 工作流 → 上传 Apple 开发者证书和描述文件；
4. 云端自动 `flutter build ipa`，产物直接下载或发 TestFlight。

### 路线 C：租用云 Mac（MacinCloud 等），远程操作 Xcode 打包。

## 四、常见报错排查

| 报错 | 解决 |
|---|---|
| `CocoaPods not installed` | `sudo gem install cocoapods` 后重新 build |
| `pod install` 卡住/超时 | 换国内镜像：`export COCOAPODS_CDN_URL=...` 或使用代理 |
| pub get 版本冲突 | 按 pubspec.yaml 依赖版本放宽约束，或 `flutter pub upgrade --major-versions` |
| 通知收不到 | iOS 首次需在"设置→通知"允许；真机测试（模拟器通知时机不准） |
| `Provisioning profile 不匹配` | Xcode → Signing & Capabilities 里选自己的 Team，勾选 Automatically manage signing |
| 签名 7 天过期（免费账号） | 重新用 Xcode Run 一次即可续签；想长期用就上 99 美元/年的开发者账号 |

## 五、数据与隐私

- 所有数据只存手机本地（SharedPreferences + SQLite），无网络请求、无账号、无第三方 SDK。
- 通知为纯本地通知，不需要服务器。

## 免责声明

本 App 为自我管理工具，健康里程碑内容依据世界卫生组织戒烟收益时间轴整理，不构成医疗建议。烟龄长或烟量大者建议前往戒烟门诊（可拨打 12320 卫生热线咨询）。
