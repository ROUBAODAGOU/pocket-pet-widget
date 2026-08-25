# Development Plan — PocketPal iOS Widget 原型

> 本文件记录开发阶段、依赖、验证门禁和剩余工作。
> 当前状态：Product Spec 已确认；Design Brief 与设计稿缺失，视觉实现按 Product Spec 第 10 节降级执行。
> 运行约束：开发主环境为 Windows；日常编译测试使用 GitHub Actions macOS runner，真实主屏幕 Widget 集中到远程 Mac 做最终人工验收。

---

## Phase 1：可复现 Xcode 工程与云端验证骨架

**状态：** 已完成（2026-08-25；GitHub Actions `iOS CI` run `32816753654` 全绿）

**验证证据：**

- 验证提交：`58aef4e17473e9744ca827095c879b15fd7cf4c9`。
- GitHub Actions：<https://github.com/ROUBAODAGOU/pocket-pet-widget/actions/runs/32816753654>，工程生成、App 与 Widget 编译、模拟器测试和制品上传全部成功。
- 自动测试：Unit Tests 1/1、UI Tests 1/1 通过，构建日志以 `TEST SUCCEEDED` 结束。
- CI 制品：`pocketpal-ios-verification`，包含 `PocketPal.xcresult` 与 `xcodebuild.log`。

**交付内容：**

- 建立可由 XcodeGen 2.46.0 重复生成的 iOS App、Widget Extension、Unit Tests 和 UI Tests 工程。
- 配置 iOS 17.0 最低部署目标、Xcode 26.6 / Swift 6.3 工具链、App Group entitlement 占位标识和 `pocketpal://` URL Scheme。
- 创建能启动的 App 空壳与能被系统识别的三尺寸 Widget 空壳，先打通工程依赖和 target membership。
- 建立 GitHub Actions macOS CI，自动生成工程、编译 App 与 Widget、运行测试并上传 `.xcresult` 与日志。

**关键文件：**

- `project.yml` — XcodeGen 工程事实源，定义四个 target、scheme、构建设置、资源和 target 依赖。
- `.github/workflows/ios-ci.yml` — macOS 26 runner 上的工程生成、构建、测试和制品上传流程。
- `PocketPal/App/PocketPalApp.swift` — iOS App 入口和最小可启动界面。
- `PocketPal/Widget/PocketPalWidgetBundle.swift` — Widget Extension 入口。
- `PocketPal/Widget/PocketPalWidget.swift` — 支持 `.systemSmall/.systemMedium/.systemLarge` 的最小 Widget 配置。
- `PocketPal/Configuration/PocketPal.entitlements` — App 的 App Group entitlement。
- `PocketPal/Configuration/PocketPalWidget.entitlements` — Widget Extension 的同组 entitlement。
- `PocketPal/Configuration/Info.plist` — App URL Scheme 与基础元数据。
- `PocketPal/Configuration/Widget-Info.plist` — Widget Extension 元数据。

**验收标准：**

- `xcodegen generate` 在 macOS runner 成功生成 `PocketPal.xcodeproj`，且工程列表包含 App、Widget、Unit Tests、UI Tests 四个 target。
- CI 能编译 App 和 Widget Extension，Widget 嵌入 App 产物，无循环依赖或 target membership 错误。
- CI 能启动一个可用 iOS Simulator，运行空测试并上传可下载的 `.xcresult`。
- App 启动后出现 PocketPal 工程状态页；Widget target 的三种 family 均通过编译。

**本阶段如何验证：**

1. Windows 上打开 [Phase 1 成功运行](https://github.com/ROUBAODAGOU/pocket-pet-widget/actions/runs/32816753654)，确认 `Generate → Build → Test → Upload artifacts` 全绿。
2. 从运行页下载 `pocketpal-ios-verification`，检查 `xcodebuild.log` 中的 `TEST SUCCEEDED` 和测试数量。
3. 本阶段不需要远程桌面 Mac；真实主屏幕 Widget 交互仍按 Phase 7 的人工清单验收。

---

## Phase 2：宠物状态引擎与共享持久化

**状态：** 进行中（领域规则、共享持久化与 Use Case 实现）

**依赖：** Phase 1

**交付内容：**

- 实现 GameState、Pet、Inventory、Cooldowns、GrowthEvent 和 WidgetSnapshot 等领域模型。
- 实现确定性的时间投影、动作优先级、三种互动、金币购买和冷却规则。
- 实现基于 App Group 共享容器的 Codable JSON 仓库，包含 schemaVersion、原子替换、最近有效备份和损坏恢复。
- 实现查询、互动和购买 Use Case；App、Widget 与 App Intent 后续只依赖 Use Case 和 Repository 协议，不直接修改状态或接触具体存储。
- 定义可注入的 `DateProviding` 与 `WidgetRefreshNotifying` 端口；修改成功保存后恰好刷新一次，失败不刷新，查询不刷新也不写回时间投影。
- 提供内存仓库和 CI 临时容器，确保无开发者签名时仍可测试业务规则，同时不伪装成 App Group 实机验证。
- 在 App 状态页展示一份由领域层生成的样例快照，使本阶段结果可运行、可见。

**关键文件：**

- `PocketPal/Shared/Domain/GameState.swift` — 唯一事实状态及 schema 版本。
- `PocketPal/Shared/Domain/Pet.swift` — 宠物、动作与显示状态定义。
- `PocketPal/Shared/Domain/Inventory.swift` — 饼干库存与可重复玩具。
- `PocketPal/Shared/Domain/GrowthEvent.swift` — 最近 100 次互动事件结构。
- `PocketPal/Shared/StateEngine/PetStateEngine.swift` — 时间投影和当前动作纯函数。
- `PocketPal/Shared/Persistence/PetRepository.swift` — 持久化协议。
- `PocketPal/Shared/Persistence/AppGroupPetRepository.swift` — 共享容器 JSON、原子保存和备份恢复。
- `PocketPal/Shared/Persistence/InMemoryPetRepository.swift` — 单元测试与 SwiftUI Preview 数据源。
- `PocketPal/Shared/Persistence/SharedContainerResolver.swift` — 正式 App Group、测试临时目录和错误状态的显式分流。
- `PocketPal/Shared/Time/DateProviding.swift` — 生产系统时钟与测试固定时钟的协议边界。
- `PocketPal/Shared/UseCases/GetPetSnapshotUseCase.swift` — 只读事实状态并生成当前投影，不保存、不刷新。
- `PocketPal/Shared/UseCases/PerformPetInteractionUseCase.swift` — 三种互动的事务式读取、投影、校验、保存和刷新。
- `PocketPal/Shared/UseCases/PurchaseSnackUseCase.swift` — 金币购买食物的事务式用例。
- `PocketPal/Shared/WidgetBridge/WidgetRefreshNotifying.swift` — 不依赖 WidgetKit 的刷新端口、No-op 与测试 Spy 支点。
- `PocketPal/Shared/WidgetBridge/WidgetCenterRefreshNotifier.swift` — 封装 WidgetKit reload 的生产实现。
- `PocketPalTests/StateEngineTests.swift` — 时间、边界、冷却和动作优先级回归。
- `PocketPalTests/PersistenceTests.swift` — 编解码、原子写入、备份和损坏恢复回归。
- `PocketPalTests/PetUseCaseTests.swift` — 成功/失败保存、刷新次数和只读查询副作用回归。

**验收标准：**

- 测试时钟推进 1、12、24 小时后，饥饿和心情严格按 Product Spec 规则变化，时间倒退不产生反向收益。
- 喂食、抚摸、玩耍和购买食物的成功与失败路径均不会越界，也不会部分扣减或产生错误历史。
- 第 101 条成长事件写入后只保留最近 100 条。
- 主文件损坏时能读取最近有效备份；主文件和备份均损坏时返回可展示错误，不静默重置用户数据。
- 查询 Use Case 不保存投影状态且刷新次数为 0；修改成功保存后刷新次数为 1，校验失败或保存失败时刷新次数为 0。
- Domain、StateEngine 和 UseCases 不导入 SwiftUI、WidgetKit、AppIntents 或具体 Repository 类型。
- CI 编译和全部领域、持久化单元测试通过，App 能显示样例 WidgetSnapshot。

**本阶段如何验证：**

1. 查看 CI 的单元测试摘要，确认状态引擎和持久化测试全部通过。
2. 下载 `.xcresult`；失败时可看到具体输入时间、动作和预期数值。
3. 本阶段的 App Group 真容器仍属于最终 Mac 人工验收项，CI 只验证同一仓库实现与文件语义。

---

## Phase 3：领养、家园与 App 内互动闭环

**状态：** 未开始

**依赖：** Phase 2

**交付内容：**

- 实现首次领养、1–12 个可见字符命名校验和再次启动恢复。
- 实现家园页的宠物、当前动作、四项状态、库存提示与三个互动按钮。
- 实现 App 前后台切换时的时间投影、反馈文案，并通过修改 Use Case 在成功保存后请求 Widget 重载。
- 使用可替换的 SwiftUI 矢量宠物组件交付奶油团子猫基础姿态，保持非像素、圆润和马卡龙方向。
- 建立 App UI 冒烟测试并上传领养页、家园页、深色模式和最大字号截图。

**关键文件：**

- `PocketPal/App/RootView.swift` — 根据是否已领养切换领养页与主应用。
- `PocketPal/App/AppStore.swift` — 主线程 UI 状态、Use Case 调用和错误恢复，不直接访问具体 Repository。
- `PocketPal/App/Features/Adoption/AdoptionView.swift` — 宠物展示、命名和领养确认。
- `PocketPal/App/Features/Home/HomeView.swift` — 家园主布局和状态反馈。
- `PocketPal/App/Features/Home/StatusCard.swift` — 心情、饥饿、亲密度、金币卡片。
- `PocketPal/App/Features/Home/InteractionButtons.swift` — 喂食、抚摸、玩耍及冷却状态。
- `PocketPal/Shared/DesignSystem/PetAvatarView.swift` — 可按动作切换的 SwiftUI 矢量宠物。
- `PocketPal/Shared/DesignSystem/DesignTokens.swift` — 马卡龙浅色、深色语义色、间距和圆角。
- `PocketPal/Resources/Localizable.xcstrings` — 简体中文文案与后续本地化键。
- `PocketPalUITests/AdoptionAndHomeUITests.swift` — 首次领养、校验、重启恢复与 App 内互动冒烟测试。

**验收标准：**

- 无宠物时启动进入领养页；空白、全空格或超长名称不能创建状态，错误原因可见。
- 有宠物时重启直接进入家园，名称、数值和库存与上次保存一致。
- App 内三种互动均按规则改变状态，冷却中的重复点击不写入历史。
- CI UI 测试完成“领养 → 家园 → 三种互动”主路径并上传关键截图。
- 浅色、深色和最大辅助字号截图中，名称、四项状态和至少一个可用操作不被裁切。

**本阶段如何验证：**

1. 在 Windows 下载 CI 的 `ui-screenshots` 制品查看四组页面截图。
2. 在 Actions 测试摘要确认领养、恢复和互动流程通过。
3. 这一阶段不要求人工操作主屏幕 Widget。

---

## Phase 4：三尺寸 Widget 与时间线展示

**状态：** 未开始

**依赖：** Phase 2、Phase 3

**交付内容：**

- 实现小、中、大三种 Widget 视图，均显示宠物、当前动作、心情、饥饿、亲密度和金币。
- 实现未领养 placeholder、正常 snapshot、数据损坏 error 和敏感信息脱敏状态。
- 通过查询 Use Case 按动作结束、睡眠切换和数值跨阈值等关键时间生成未来 12 小时投影；只在必要时添加低频兜底条目，不把 Widget 当常驻进程。
- 实现 Debug Widget Preview Harness，在 App 内按真实尺寸比例展示三种 family 和典型状态并供 CI 截图。

**关键文件：**

- `PocketPal/Widget/PocketPalTimelineProvider.swift` — 只读查询 Use Case、关键转换时间投影和刷新策略，不写状态也不触发刷新通知。
- `PocketPal/Widget/PocketPalEntry.swift` — 时间线条目和渲染快照。
- `PocketPal/Widget/Views/SmallPetWidgetView.swift` — 小号 Widget 和一个上下文主操作位置。
- `PocketPal/Widget/Views/MediumPetWidgetView.swift` — 中号 Widget 双栏布局和三个操作位置。
- `PocketPal/Widget/Views/LargePetWidgetView.swift` — 大号场景、进度条和成长摘要。
- `PocketPal/Widget/Views/WidgetRootView.swift` — family、placeholder、错误和隐私状态分派。
- `PocketPal/App/Debug/WidgetPreviewHarnessView.swift` — CI 可启动的三尺寸预览画廊，仅 Debug 构建可见。
- `PocketPalUITests/WidgetPreviewHarnessUITests.swift` — 三尺寸、深浅模式、字号与典型状态截图。

**验收标准：**

- Widget Extension 编译通过并声明 `.systemSmall/.systemMedium/.systemLarge`。
- 三种视图都包含五项必需信息，VoiceOver 标签不依赖缩写或纯图标猜测。
- TimelineProvider 使用共享 StateEngine 投影未来状态，未来条目不反写 GameState。
- TimelineProvider 不采用固定 15 分钟轮询，查询路径的保存次数与 Widget 刷新通知次数均为 0。
- CI 上传未领养、开心、饥饿、睡觉和错误状态下的三尺寸截图。
- Debug Preview Harness 与 Release 产物隔离，不在正式 App 导航中暴露。

**本阶段如何验证：**

1. Windows 上查看 CI 上传的三尺寸截图矩阵。
2. 确认 Widget target build 和时间线单元测试通过。
3. “Widget Gallery 可添加、真实容器边距正确”保留到最终远程 Mac 人工验收。

---

## Phase 5：App Intents 互动与页面深链

**状态：** 未开始

**依赖：** Phase 3、Phase 4

**交付内容：**

- 实现喂食、抚摸、玩耍三个 App Intent，在 Widget Extension 进程内完成共享状态更新。
- 将中号和大号的三个操作位置接为 `Button(intent:)`，将小号接为上下文主操作。
- 实现未领养、无食物和需要完整管理时的 `Link`/`widgetURL` 深链，不用假按钮打开 App。
- 实现 `pocketpal://adopt/home/backpack/growth` 路由和非法路径降级。
- 对 Intent 返回前的持久化、失败处理和 Widget 时间线重载建立自动测试。
- 三个 Intent 只调用修改 Use Case，不直接访问具体 Repository 或复制状态规则。

**关键文件：**

- `PocketPal/Shared/Intents/FeedPetIntent.swift` — 喂食 App Intent。
- `PocketPal/Shared/Intents/PetPetIntent.swift` — 抚摸 App Intent。
- `PocketPal/Shared/Intents/PlayPetIntent.swift` — 玩耍 App Intent。
- `PocketPal/Shared/Intents/IntentDependencies.swift` — App 与 Widget 共用的 Use Case 组合入口。
- `PocketPal/Shared/Routing/AppRoute.swift` — 深链枚举和 URL 解析。
- `PocketPal/App/AppRouter.swift` — App 内页面跳转与非法路径降级。
- `PocketPalTests/AppIntentIntegrationTests.swift` — Intent 成功、冷却、无库存、失败无部分写入测试。
- `PocketPalUITests/DeepLinkUITests.swift` — 四条合法深链与非法路径回退测试。

**验收标准：**

- 三个 App Intent 都在返回前完成状态保存；失败被转换为可恢复结果，不把异常直接抛给用户。
- 每个成功 Intent 在保存后恰好请求一次 Widget 刷新；校验失败或保存失败时不请求刷新。
- 中号和大号均连接三个 Intent，小号只连接当前快照选择出的一个有效 Intent。
- 食物为 0 时喂食位置变为背包 Link；未领养时任一 family 打开领养页。
- CI 的 Intent 集成测试证明 App 未前台运行时所使用的共享业务路径可执行。
- CI 的深链 UI 测试能分别落到领养、家园、背包、成长入口；非法路径回到安全默认页。

**本阶段如何验证：**

1. Windows 上查看 Intent 和深链测试结果。
2. 下载 UI 截图确认四个深链落点。
3. 真实 Widget 按钮的点击反馈和系统重载时机保留到最终远程 Mac 人工验收。

---

## Phase 6：背包、成长记录与数据设置

**状态：** 未开始

**依赖：** Phase 3、Phase 5

**交付内容：**

- 实现家园、背包、成长三栏 Tab 与深链选中状态。
- 实现用 3 金币补充 1 块星星饼干、金币不足反馈和可重复彩虹球展示。
- 实现领养天数、累计互动、亲密度摘要、最近 100 条成长时间线和清空记录。
- 实现改名、本地保存说明和二次确认后的全部数据重置。
- 完成 App 内“玩耍赚金币 → 买饼干 → 喂食 → 成长回看”的 UI 测试闭环。

**关键文件：**

- `PocketPal/App/MainTabView.swift` — 家园、背包、成长三栏导航和深链联动。
- `PocketPal/App/Features/Backpack/BackpackView.swift` — 库存、食物补充、金币不足和玩具展示。
- `PocketPal/App/Features/Growth/GrowthView.swift` — 摘要、空状态和时间线。
- `PocketPal/App/Features/Growth/GrowthEventRow.swift` — 动作时间与数值变化行。
- `PocketPal/App/Features/Settings/DataSettingsView.swift` — 改名、本地说明、清空与重置入口。
- `PocketPal/App/Features/Settings/ResetConfirmationView.swift` — 二次确认与不可逆后果说明。
- `PocketPalUITests/InventoryGrowthSettingsUITests.swift` — 金币闭环、清空记录、改名和全部重置流程。

**验收标准：**

- 金币足够时购买精确扣 3 并加 1 块饼干；不足时不改变任何状态。
- 成长页无记录时显示引导，有记录时按时间倒序且最多 100 条。
- 清空历史不改变当前数值；重置全部数据后 App 回到领养页。
- 重置后 WidgetRepository 读取到未领养状态，下一次时间线重载不再展示旧宠物。
- CI UI 测试完成完整 App 经济与数据管理闭环并上传截图。

**本阶段如何验证：**

1. Windows 上查看端到端测试摘要和背包、成长、设置截图。
2. 下载测试结果确认清空与重置断言。
3. Widget 重置后的真实主屏幕变化保留到最终远程 Mac 人工验收。

---

## Phase 7：无障碍、视觉收尾与远程 Mac 验收包

**状态：** 未开始

**依赖：** Phase 1–6

**交付内容：**

- 收敛奶油团子猫的闲逛、睡觉、找食物、吃饭、被摸、玩耍和难过七种姿态与统一马卡龙视觉变量。
- 完成深色模式、最大辅助字号、VoiceOver 标签/提示、非纯颜色表达和触控尺寸回归。
- 建立 CI 总门禁：生成工程、编译 App/Widget、单元测试、UI 测试、截图矩阵与结果包全部通过。
- 输出远程 Mac 人工验收清单，集中验证 Widget Gallery、三尺寸主屏幕、App 关闭时三个按钮、无食物深链、刷新和 VoiceOver 顺序。
- 输出 Windows 用户可执行的运行与取证说明；未做远程 Mac 人工验收时明确标记为“自动测试通过，真实 Widget 未人工验收”。

**关键文件：**

- `PocketPal/Shared/DesignSystem/PetPose.swift` — 七种宠物姿态与状态映射。
- `PocketPal/Shared/DesignSystem/AccessibleStatusLabel.swift` — 图标、文字、数值和 VoiceOver 的统一表达。
- `PocketPalUITests/AccessibilityAndAppearanceUITests.swift` — 深浅模式、字号和可访问标识回归。
- `.github/workflows/ios-ci.yml` — 完整测试矩阵、截图和结果包门禁。
- `VALIDATION.md` — Windows 查看 CI 结果、远程 Mac 操作和验收取证步骤。
- `README.md` — 生成工程、Xcode 运行、添加 Widget 和已知限制。

**验收标准：**

- 所有 P0 Requirement 和 AC-001 至 AC-013 都能映射到自动或人工验收证据。
- CI 总门禁通过，制品包含 App/Widget 构建日志、`.xcresult`、App 页面截图和 Widget Preview Harness 截图。
- 远程 Mac 上可从 Widget Gallery 添加三种尺寸；中号和大号在 App 未前台运行时能触发三种动作。
- 无食物时喂食入口打开背包；重置后三种 Widget 都变为未领养状态。
- 最大辅助字号和 VoiceOver 下，核心状态与操作仍可理解；深色模式无不可读对比。

**本阶段如何验证：**

1. Windows 上先确认 CI 总门禁和全部制品齐全。
2. 临时租用或借用一台可交互 Mac，在 Xcode 打开生成后的工程并运行 `VALIDATION.md` 的人工清单。
3. 保存三尺寸主屏幕截图和测试记录；完成后才把版本标记为“可运行原型已验收”。

---

## 技术栈

| 层级 | 技术 | 版本 / 基线 | 说明 |
|---|---|---|---|
| 语言 | Swift | 6.3 | Xcode 26.6 内置；工程使用 Swift 6 语言模式并启用严格并发检查 |
| IDE / SDK | Xcode | 26.6 stable | 当前 `macos-26` runner 可用的固定版本；最低部署仍为 iOS 17.0 |
| App UI | SwiftUI | iOS 17+ API 基线 | App、Preview Harness、深色模式和 Dynamic Type |
| 小组件 | WidgetKit | iOS 17+ | 小、中、大主屏幕 Widget 与时间线 |
| 快捷互动 | App Intents | iOS 17+ | Widget `Button(intent:)` 的喂食、抚摸、玩耍 |
| 本地数据 | Codable JSON + App Group container | Apple 原生 | 单一 GameState、原子保存、备份恢复；无数据库 |
| 工程生成 | XcodeGen | 2.46.0 | 从 Windows 可维护的 `project.yml` 在 macOS 生成工程 |
| 自动化 | GitHub Actions macOS runner | `macos-26` | 生成、编译、模拟器测试、截图与制品上传 |
| 测试 | XCTest + XCUITest | Xcode 26.6 内置 | 规则、持久化、Intent、App 流程与无障碍冒烟 |
| 生产依赖 | 无第三方运行时依赖 | 不适用 | 降低 Widget Extension 体积和兼容风险 |

## 数据存储

本版本不使用数据库或服务端。Phase 2 在 App Group 共享容器中建立一个带 `schemaVersion` 的 `game-state.json` 和一个最近有效备份文件；App、Widget TimelineProvider 与 App Intents 经同一个 `PetRepository` 访问。

架构只吸收参考项目中可证明有价值的边界：纯状态策略、Use Case、Repository、可替换 Widget 刷新端口与对应测试。继续使用 XcodeGen、Codable JSON 和单工程共享源码；不引入 SwiftData、Tuist、iOS 18 门槛或每 Feature 五 Target 的微模块结构。

## 功能依赖图

```text
Phase 1 工程 + CI
└─ Phase 2 状态引擎 + 共享持久化
   ├─ Phase 3 领养 + 家园
   │  └─ Phase 4 三尺寸 Widget 展示
   │     └─ Phase 5 App Intents + 深链
   │        └─ Phase 6 背包 + 成长 + 设置
   └────────────────────────────────────┐
                                        └─ Phase 7 无障碍 + 最终验收
```

## Spec 覆盖映射

| Product Spec | 开发阶段 |
|---|---|
| SCOPE-001、REQ-001 领养与命名 | Phase 3 |
| SCOPE-002 App 家园 | Phase 3 |
| SCOPE-003、REQ-003 三尺寸 Widget | Phase 4 |
| SCOPE-004 小组件直接互动 | Phase 5 |
| SCOPE-005 时间状态变化 | Phase 2、Phase 4 |
| SCOPE-006 本地共享数据 | Phase 2 |
| SCOPE-007、REQ-004 背包与金币 | Phase 6 |
| SCOPE-008、REQ-005 成长记录 | Phase 2、Phase 6 |
| SCOPE-009 深色模式与无障碍 | Phase 3、Phase 4、Phase 7 |
| SCOPE-010 数据管理 | Phase 6 |

## 已知风险与限制

- GitHub Actions 能验证编译、测试和 App 内截图，不能自动完成 SpringBoard 的长按添加 Widget 和真实按钮点击；这部分必须保留人工门禁。
- WidgetKit 刷新由系统调度，测试只能验证时间线内容与交互后重载，不承诺精确到某一分钟。
- App Group 的正式 identifier 与签名团队相关；当前使用占位标识，最终远程 Mac 或 TestFlight 前必须替换并核对两个 target 的 entitlement 完全一致。
- 没有 Design Brief 和最终插画稿；计划使用可替换的 SwiftUI 矢量宠物完成原型。若后续制作设计稿，UI 以设计稿为准并更新本计划受影响文件。
- GitHub Actions 的标准 runner 对公开仓库免费；私有仓库受账户免费额度和超额计费影响，CI 应避免无意义重复运行。
- CI 下载的 XcodeGen 必须校验官方发布 SHA-256；第三方 GitHub Actions 必须固定到完整 commit SHA，不使用可移动 major tag。
- TestFlight 真机验证是可选项，需要 Apple Developer Program；不影响先完成远程 Mac 模拟器原型验收。

## 开发规则

- 每完成一个 Phase 执行：Code Review → 测试完整性 → 云端编译验证 → 功能验证。
- 云端编译或测试未通过，Phase 状态不得标记完成。
- 需要真实 Widget 的验收项必须明确标注“等待远程 Mac”，不能用 Preview Harness 截图代替。
- 所有 App、Widget 和 App Intent 的查询或修改必须经过对应 Use Case；不得直接调用具体 Repository、修改 `GameState` 或各写一套规则。
- 修改 Use Case 只有在保存成功后才能通过 `WidgetRefreshNotifying` 通知一次；查询、Preview、Timeline 渲染和失败路径不得通知。
- Domain、StateEngine 和 UseCases 不得导入 SwiftUI、WidgetKit、AppIntents 或具体持久化实现；MVP 不为形式上的 Clean Architecture 拆分额外 Target。
- 不实现 Product Spec 的 OUT-001 至 OUT-009。
- 没有第三方生产依赖；XcodeGen 仅是工程生成工具。
- Git 提交使用 `feat`、`fix`、`refactor` 或 `chore` 前缀；不覆盖工作区中的无关改动。
