# 变更记录

## [v1.3] - 2026-08-25

### 新增

- 新增 Use Case、`WidgetRefreshNotifying` 和 `DateProviding` 架构约束，统一 App、Widget 与 App Intent 的状态访问路径。
- 新增刷新行为验收：保存成功后恰好通知一次，校验或保存失败不通知，查询与时间线渲染不通知。
- 新增竞品参考决策，仅吸收 YuGeonHui/Tamagotchi 的工程分层与测试方法。

### 修改

- 将 App 与 Widget 的状态修改入口从泛化的 `InteractionService` 明确为查询和修改 Use Case。
- 将 Widget 时间线从约每 30 分钟固定投影修改为关键状态转换时间点加低频兜底条目。
- 明确继续使用 iOS 17、Codable JSON、XcodeGen 和轻量共享源码，不采用参考项目的 Emoji UI、SwiftData、iOS 18、Tuist 或五 Target 微模块。

---

## [v1.2] - 2026-08-24

### 修改

- 将云端开发工具链从笼统的 Xcode 26 / Swift 6.2 更新并固定为当前 macOS runner 可用的 Xcode 26.6 / Swift 6.3。
- 明确编译 SDK 升级不改变 iOS 17.0 最低部署目标。

---

## [v1.1] - 2026-08-24

### 新增

- 新增无本地 Mac 的两层验证策略：GitHub Actions macOS 自动编译测试 + 短期远程 Mac 最终人工 Widget 验收。
- 新增 XcodeGen 2.46.0 可复现工程、CI 截图和 Debug Widget Preview Harness 要求。
- 新增已确认决策，记录 MVP 基线与当前设备约束。

### 修改

- 将文档状态从“方案待确认”修改为“MVP 基线已确认，可进入开发计划”。
- 将各开发阶段的验证说明改为 Windows 可查看的 CI 证据，并把 SpringBoard Widget 交互单列为最终人工验收。
- 将完成定义改为分别验收云端自动测试和真实 Widget 人工测试，禁止混为一项。

---

## [v1.0] - 2026-08-24

- 初始版本：定义一只宠物、三种互动、基础数值、三尺寸 Widget、本地共享数据、页面结构与 SwiftUI/WidgetKit/App Intents 技术方案。
