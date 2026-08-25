# 产品需求规范：PocketPal（工作名）

> 文档状态：MVP 基线已于 2026-08-24 获用户确认；可进入开发计划。
> 产品形态：iPhone App + 主屏幕小组件原型。

## 0. AI 使用说明

- 本文档是本原型功能、范围、行为与验收标准的事实来源。
- AI MUST 优先实现 P0，不得自行加入社交、付费、多宠物或联网功能。
- AI MUST 根据本文验收标准判断完成，不得把“代码已写”当作“可运行”。
- 未确认事项按第 13 节假设执行；阻塞项未确认时不得进入开发。

## 1. 产品上下文

### 1.1 产品摘要

PocketPal 是一款以 iPhone 主屏幕小组件为核心触点的轻量虚拟宠物应用。用户领养并命名一只二维卡通宠物，通过喂食、抚摸和玩耍维持它的状态；App 用于更完整的互动、补充食物与回看成长记录。

### 1.2 用户问题

目标用户想在频繁查看 iPhone 主屏幕时获得低负担、可持续的可爱陪伴，但现有虚拟宠物产品常把体验做成重养成、社交关系、广告经济或像素怀旧。用户需要的是“看一眼就有反馈，点一下就能照顾”的轻互动，而不是再养一个需要打卡的任务系统。

> 上述问题是根据用户提出的形态与竞品现状作出的产品假设，尚未经过真实用户访谈验证。本项目当前定位为体验原型，不把市场需求验证作为编码前置条件。

### 1.3 目标用户

| 用户类型 | 描述 | 核心需求 |
|---|---|---|
| 主要用户 | 喜欢治愈系数字陪伴、每天多次查看 iPhone 主屏幕，但不愿投入重度游戏时间的人 | 不打开 App 也能快速看见宠物状态并完成一次互动 |
| 次要用户 | 喜欢装饰主屏幕、愿意把小组件作为情绪化视觉元素的人 | 三种尺寸都好看，状态一眼可读，深浅模式均协调 |

### 1.4 核心 Job

当用户在一天中短暂查看手机时，帮助他用几秒钟确认并照顾一个有反馈的数字伙伴，从而获得连续但没有负担的陪伴感。

### 1.5 核心价值

主屏幕就是主要体验面：可见、可懂、可互动；App 是扩展空间，不是每次操作都必须经过的入口。

### 1.6 成功标准

| 判断标准 | MVP 目标 / 信号 |
|---|---|
| 首次体验闭环 | 新用户可在 3 分钟内完成领养、命名、添加小组件并完成第一次互动 |
| 小组件价值成立 | 喂食、抚摸、玩耍三种动作均可至少在中号和大号小组件内直接完成，不强制打开 App |
| 状态一致性 | 同一次互动完成后，App 与小组件读取到相同的心情、饥饿、亲密度、金币和当前动作 |
| 离线可用 | 断网时领养、互动、背包、记录和小组件仍可工作 |
| 可访问性 | 深色模式、VoiceOver 和系统最大辅助字号下，核心状态与主要操作仍可识别和触发 |

### 1.7 产品判断

- 这是“维生素型”情绪产品，不是刚需工具；留存靠宠物表现和低摩擦反馈，不能靠惩罚、死亡或强制打卡制造焦虑。
- MVP 不需要 AI。把 AI 换成确定性规则后核心价值完全保留；引入模型只会增加网络、延迟、成本和不可控性。
- 竞品已经覆盖多宠物、社交共养、小游戏和付费装饰。原型的差异不是功能更多，而是非像素的柔和二维插画、单宠物聚焦和真正以小组件为第一界面。

## 2. MVP 范围

### 2.1 P0：本版本必须完成

| 编号 | 内容 | 优先级 | 备注 |
|---|---|---|---|
| SCOPE-001 | 领养并命名一只宠物 | P0 | 首版固定一种宠物，工作设定为“奶油团子猫” |
| SCOPE-002 | App 家园页 | P0 | 展示宠物、五项状态与三种互动 |
| SCOPE-003 | 小/中/大三种主屏幕小组件 | P0 | 三种尺寸均展示宠物和核心状态 |
| SCOPE-004 | 小组件直接互动 | P0 | 使用 App Intents 完成喂食、抚摸、玩耍 |
| SCOPE-005 | 时间驱动状态变化 | P0 | 用确定性规则惰性计算，不依赖常驻后台任务 |
| SCOPE-006 | 本地共享数据 | P0 | App Group 共享容器，App 与 Widget 共用同一状态源 |
| SCOPE-007 | 最小背包 | P0 | 一种消耗品“星星饼干”，支持用金币补充 |
| SCOPE-008 | 成长记录 | P0 | 记录最近 100 次成功互动与关键数值变化，可清空 |
| SCOPE-009 | 深色模式和基础无障碍 | P0 | 动态字体、VoiceOver、足够对比度和不只依赖颜色表达 |
| SCOPE-010 | 数据管理 | P0 | 支持改名、清空成长记录和重置全部本地数据 |

### 2.2 P1：P0 稳定后再做

| 编号 | 内容 | 优先级 | 备注 |
|---|---|---|---|
| SCOPE-011 | 更丰富的 App 内动画与触感反馈 | P1 | 不影响核心数据链路 |
| SCOPE-012 | 亲密度里程碑 | P1 | 仅解锁台词或姿态，不新增成长形态 |
| SCOPE-013 | 小组件背景主题选择 | P1 | 先预留主题模型，不做商店 |

### 2.3 明确不做

| 编号 | 内容 | 原因 |
|---|---|---|
| OUT-001 | 多宠物、繁殖、宠物切换 | 会扩大数据模型、配置和 Widget 选择逻辑，偏离最小闭环 |
| OUT-002 | 登录、云同步、社交、共养 | 首版验证本地体验，不引入账号和后端 |
| OUT-003 | 真实支付、订阅、广告 | 原型先验证互动，不验证商业化 |
| OUT-004 | 装饰商店、房间编辑 | 只保留可扩展接口，不做内容生产系统 |
| OUT-005 | 小游戏 | “玩耍”先作为一次确定性动作，不进入游戏玩法 |
| OUT-006 | 宠物生病、死亡、离家或连续打卡惩罚 | 治愈定位不靠焦虑驱动 |
| OUT-007 | 实时连续动画与秒级刷新 | WidgetKit 不是常驻渲染进程，系统控制刷新时机 |
| OUT-008 | iPad、Apple Watch、Live Activity、锁屏小组件 | 首版只验收 iPhone 主屏幕小组件 |
| OUT-009 | AI 对话、生成宠物或云端内容 | MVP 无需 AI，避免引入网络和概率性失败 |

## 3. 用户任务

| 编号 | 用户任务 | 用户类型 | 优先级 |
|---|---|---|---|
| TASK-001 | 用户领养并命名自己的数字宠物 | 主要用户 | P0 |
| TASK-002 | 用户从主屏幕快速判断宠物当前需要什么 | 主要用户 | P0 |
| TASK-003 | 用户用一次点击完成喂食、抚摸或玩耍 | 主要用户 | P0 |
| TASK-004 | 用户在 App 内管理食物并查看成长轨迹 | 主要用户 | P0 |
| TASK-005 | 用户改名、清理记录或重置原型数据 | 主要用户 | P0 |

## 4. 页面结构

### 4.1 信息架构

```text
首次启动
└─ 领养页
   └─ 命名确认
      └─ 主应用（三栏 Tab）
         ├─ 家园
         │  └─ 数据设置（顶部入口）
         ├─ 背包
         └─ 成长

主屏幕
├─ 小号 Widget
├─ 中号 Widget
└─ 大号 Widget
```

### 4.2 SCREEN-001：领养页

- 上半区：宠物大插画、待机表情和简短欢迎语。
- 下半区：名称输入框、字符计数、确认领养按钮。
- 名称规则：去除首尾空白后 1–12 个可见字符；禁止只有空白或换行；允许中文、英文、数字和 Emoji。
- 首次无数据时显示；已有宠物时不重复出现。
- 确认后创建初始状态：心情 80、饥饿 20、亲密度 0、金币 10、星星饼干 5。

### 4.3 SCREEN-002：家园页

- 顶部：宠物名、当前动作、设置入口。
- 中部：占视觉主位的宠物二维插画；App 内允许轻量眨眼、弹跳和动作过渡。
- 状态区：心情、饥饿、亲密度、金币四张信息卡；图标、文字和数值同时表达。
- 互动区：喂食、抚摸、玩耍三个大按钮；按钮显示库存或冷却信息。
- 反馈区：一条短句解释刚发生的结果，例如“吃到饼干，肚子满足了一点”。
- App 回到前台时重新投影时间状态并刷新界面。

### 4.4 SCREEN-003：背包页

- 展示星星饼干的数量、效果和获取方式。
- “补充 1 块”消耗 3 金币；金币不足时按钮禁用并说明原因。
- 彩虹球作为已拥有、不可消耗的玩具展示，用于解释玩耍动作来源。
- 首版无拖拽、分类、稀有度、装饰或付费内容。

### 4.5 SCREEN-004：成长页

- 顶部摘要：领养天数、累计互动次数、当前亲密度。
- 时间线：最近 100 次成功互动，显示时间、动作和数值变化。
- 空状态：“还没有成长记录，去摸摸它吧”。
- 提供“清空记录”；清空只删除时间线，不改变当前宠物数值。

### 4.6 SCREEN-005：数据设置页

- 修改宠物名称。
- 查看本地保存说明。
- 重置全部数据：二次确认后删除宠物、背包与记录，返回领养页；小组件恢复“先去领养”空状态。

### 4.7 WIDGET-001：小号

- 宠物占主要面积。
- 显示当前动作短标签。
- 四个紧凑状态：心情、饥饿、亲密度、金币。
- 只放一个上下文主按钮：饥饿高时优先喂食，其余情况在抚摸和玩耍间按冷却可用性选择。
- 点击宠物主体打开家园；无宠物时显示“去领养”。

### 4.8 WIDGET-002：中号

- 左侧宠物和当前动作，右侧四项状态。
- 底部提供喂食、抚摸、玩耍三个图标按钮。
- 食物为 0 时，“喂食”位置变为打开背包的 Link，而不是执行一个注定失败的按钮。

### 4.9 WIDGET-003：大号

- 上半区是更完整的宠物场景和情绪文案。
- 中部用可读进度条展示心情、饥饿、亲密度，并单列金币。
- 下方提供三个互动按钮及最近一次成长事件。
- 点击成长摘要打开 App 成长页。

## 5. 用户流程

### FLOW-001：首次领养并添加小组件

**关联任务：** TASK-001、TASK-002
**优先级：** P0

1. 用户打开 App，看见固定宠物形象和命名输入。
2. 用户输入有效名称并确认。
3. 系统创建本地状态并进入家园页。
4. 家园页显示“如何添加小组件”的简短引导卡。
5. 用户回到主屏幕，长按并添加 PocketPal 的任一尺寸小组件。
6. 小组件从 App Group 读取同一只宠物并显示状态。

**边界：** 如果用户先添加小组件再完成领养，小组件显示领养入口；点击后深链到 App 领养页。

### FLOW-002：从小组件快速互动

**关联任务：** TASK-002、TASK-003
**优先级：** P0

1. 用户查看小组件，读取宠物动作和四项状态。
2. 用户点击可用的喂食、抚摸或玩耍按钮。
3. 对应 App Intent 读取共享状态，先结算经过时间，再校验库存与冷却。
4. 成功时系统应用数值变化、写入成长记录并请求重载小组件时间线。
5. 下一次 WidgetKit 渲染显示新动作和新数值。

**分支：** 食物为 0 时，小组件展示打开背包的入口；冷却未结束时保留状态并显示剩余时间或不可用样式。

### FLOW-003：在 App 内完整互动

**关联任务：** TASK-003、TASK-004
**优先级：** P0

1. 用户从图标、小组件主体或深链进入家园。
2. App 结算当前时间状态并展示完整数值。
3. 用户执行一次互动，看到宠物动作、数值变化和触感反馈。
4. 系统保存状态、追加记录并通知 WidgetKit 重载对应小组件。

### FLOW-004：补充食物并回看成长

**关联任务：** TASK-004
**优先级：** P0

1. 用户进入背包，用 3 金币补充 1 块星星饼干。
2. 系统立即保存库存和金币变化。
3. 用户进入成长页，查看互动时间线和累计摘要。
4. 用户可清空时间线；当前数值不回退。

## 6. 核心规则与功能需求

### 6.1 状态定义

| 状态 | 范围 | 初始值 | 解释 |
|---|---:|---:|---|
| mood / 心情 | 0–100 | 80 | 越高越开心 |
| hunger / 饥饿 | 0–100 | 20 | 越高越饿，避免“饱腹值”语义混乱 |
| intimacy / 亲密度 | 0–100 | 0 | 只增不降，MVP 不做等级重置 |
| coins / 金币 | 非负整数 | 10 | 玩耍获得，补充食物消耗 |
| snackCount / 饼干 | 非负整数 | 5 | 喂食消耗 |

### 6.2 时间结算规则

- MUST 以 `lastEvaluatedAt` 和目标时间计算差值，不依赖后台常驻计时器。
- 每经过完整 1 小时，饥饿 +3，最多 100。
- 每经过完整 1 小时，心情 -1；当投影后的饥饿达到 70 以上时，额外 -2，最多降到 0。
- 亲密度、金币和库存不随时间减少。
- 时间倒退、时区变化或系统时间异常时，差值按不小于 0 处理，不反向增加状态。
- App 与 TimelineProvider 必须调用同一个纯函数 `PetStateEngine.project(state, at:)`。

### 6.3 当前动作优先级

1. 最近一次成功互动仍在动作窗口内：吃饭 10 分钟、享受抚摸 5 分钟、玩耍 15 分钟。
2. 当地时间 22:00–07:00：睡觉。
3. 饥饿 ≥70：找吃的。
4. 心情 <40：发呆。
5. 其余：闲逛。

### REQ-001：领养与命名

**优先级：** P0
**关联任务：** TASK-001
**关联流程：** FLOW-001

**规则：**

- MUST 只允许一只宠物。
- MUST 在名称有效后才创建状态。
- MUST 支持后续改名和重置全部数据。
- SHOULD 在首次完成后显示一次小组件添加引导。

**验收：**

- AC-001：Given 无本地宠物，when 输入有效名称并确认，then 家园显示该名称且初始数值与背包一致。
- AC-002：Given 名称为空、全空白或超过 12 个可见字符，when 点击确认，then 不创建宠物并显示具体校验原因。
- AC-003：Given 已有宠物，when 再次启动 App，then 直接进入家园且不重复创建。

### REQ-002：三种互动

**优先级：** P0
**关联任务：** TASK-003
**关联流程：** FLOW-002、FLOW-003

| 动作 | 前置条件 | 数值变化 | 冷却 | 动作窗口 |
|---|---|---|---|---|
| 喂食 | 饼干 >0 且饥饿 >10 | 饼干 -1；饥饿 -30；心情 +5；亲密度 +2 | 15 分钟 | 吃饭 10 分钟 |
| 抚摸 | 距上次抚摸 ≥10 分钟 | 心情 +10；亲密度 +1 | 10 分钟 | 享受抚摸 5 分钟 |
| 玩耍 | 距上次玩耍 ≥30 分钟 | 心情 +15；饥饿 +5；亲密度 +3；金币 +2 | 30 分钟 | 玩耍 15 分钟 |

- 所有数值变化均限制在各自合法范围内。
- 条件不满足时不得写入成长记录，也不得部分扣减库存或金币。
- 成功互动写入一条含动作、时间和数值差的记录。
- 连续快速点击必须保持状态有效；同一冷却窗口只允许第一次成功。

**验收：**

- AC-004：Given 有至少 1 块饼干且饥饿为 60，when 成功喂食，then 饼干减少 1、饥饿变为 30，并新增一条喂食记录。
- AC-005：Given 抚摸仍在冷却，when 再次触发抚摸，then 所有数值和记录数量保持不变。
- AC-006：Given 玩耍可用，when 从小组件触发，then 共享状态按表更新，App 下次打开读取到相同结果。

### REQ-003：三种尺寸小组件

**优先级：** P0
**关联任务：** TASK-002、TASK-003
**关联流程：** FLOW-001、FLOW-002

- MUST 支持 `.systemSmall`、`.systemMedium`、`.systemLarge`。
- MUST 在每种尺寸展示宠物、当前动作，以及心情、饥饿、亲密度和金币。
- MUST 在中号和大号提供三个直接互动入口。
- MUST 在小号提供一个上下文主操作，并允许点击主体打开 App。
- MUST 用 App Intent 的 `Button` 执行直接动作；打开 App 使用 `Link` 或 `widgetURL`，不混淆两种行为。
- MUST 提供未领养 placeholder、数据损坏 error 和正常 snapshot。

**验收：**

- AC-007：Given 已领养宠物，when 在 Widget Gallery 预览三种尺寸，then 三种尺寸均不裁切宠物名称、动作和四项核心状态。
- AC-008：Given 中号或大号小组件，when 依次触发三个已满足前置条件的动作，then 每个动作均能通过 App Intent 更新共享状态。
- AC-009：Given 尚未领养，when 添加任一尺寸，then 显示“先去领养”且点击后打开领养页。

### REQ-004：背包与金币闭环

**优先级：** P0
**关联任务：** TASK-004
**关联流程：** FLOW-004

- 1 块星星饼干价格固定为 3 金币。
- 购买前必须校验余额；失败时不得扣金币。
- 库存和金币变化立即保存并请求 WidgetKit 重载。
- 背包读取失败时显示恢复入口，不展示伪造的 0 库存。

**验收：**

- AC-010：Given 金币为 10，when 购买 1 块饼干，then 金币为 7 且库存增加 1。
- AC-011：Given 金币少于 3，when 点击购买，then 金币和库存不变，并显示“金币不足”。

### REQ-005：成长记录与数据管理

**优先级：** P0
**关联任务：** TASK-004、TASK-005
**关联流程：** FLOW-004

- 最多保留最近 100 条成功互动；超出时移除最早记录。
- 清空记录不改变宠物当前状态。
- 重置全部数据必须二次确认；确认后删除宠物、库存、冷却和记录。

**验收：**

- AC-012：Given 有成长记录，when 清空记录，then 时间线为空但当前数值不变。
- AC-013：Given 已确认重置，when 重置完成，then App 回到领养页且小组件显示未领养状态。

## 7. 状态与异常

| 界面 | 空状态 | 加载 / 占位 | 错误 | 成功 | 无权限 |
|---|---|---|---|---|---|
| 领养 | 固定宠物等待命名 | 本地界面无需阻塞加载 | 写入失败时保留名称并可重试 | 进入家园 | 不涉及账号权限 |
| 家园 | 无宠物时回领养 | 短暂使用上次有效快照 | 数据损坏时提示恢复备份或重置 | 展示投影后的当前状态 | 不涉及账号权限 |
| 背包 | 库存可为 0，并给补充入口 | 使用上次有效快照 | 读取失败时显示重试 | 购买后原地更新 | 不涉及账号权限 |
| 成长 | 引导第一次互动 | 本地读取时用简短占位 | 读取失败时可重试 | 展示最近 100 条 | 不涉及账号权限 |
| Widget | 未领养时显示领养入口 | 提供 WidgetKit placeholder | 数据损坏时显示打开 App 修复 | 显示快照与按钮 | 锁定设备时系统可能要求先解锁，App 不绕过系统限制 |

## 8. 数据模型

### 8.1 核心实体

| 实体 | 关键字段 |
|---|---|
| `GameState` | schemaVersion、pet、inventory、cooldowns、history、lastEvaluatedAt |
| `Pet` | id、speciesID、name、adoptedAt、mood、hunger、intimacy、coins、lastInteraction |
| `Inventory` | snackCount、ownedReusableItemIDs |
| `Cooldowns` | lastFedAt、lastPettedAt、lastPlayedAt |
| `GrowthEvent` | id、occurredAt、interactionType、stateDelta、messageKey |
| `PetSpeciesDefinition` | id、displayName、assetKeys、defaultTheme；首版只有一个静态定义 |
| `WidgetSnapshot` | 只含渲染所需的宠物名、动作、四项状态、库存与按钮可用性 |

### 8.2 数据规则

- `GameState` 是唯一可写事实源，WidgetSnapshot 只从它投影，不反向写入。
- 所有持久化读写经 `PetRepository` 协议完成，界面和 App Intent 不直接操作文件。
- 状态文件使用版本号；遇到未知高版本不得覆盖原文件。
- 写入采用共享容器内临时文件 + 原子替换，并保留最近一次有效备份。
- 所有数据仅本机当前 App Group 可见；无账号、无云端上传。

## 9. 技术方案

### 9.1 平台基线

- SwiftUI + WidgetKit + App Intents。
- 开发与云端验证工具链固定为 Xcode 26.6 + Swift 6.3；最低系统版本不随编译 SDK 提升。
- 最低部署目标建议 iOS 17.0：交互式 Widget Button/Toggle 从 iOS 17 起可用。
- 两个 target：iOS App、Widget Extension；共享的 Domain、Persistence、Intents 和 Design Tokens 同时加入所需 target。
- 不引入第三方运行时依赖；状态计算、持久化和路由均使用 Apple 原生框架。

### 9.2 模块结构

```text
PocketPal/
├─ App/
│  ├─ PocketPalApp.swift
│  ├─ AppRouter.swift
│  └─ Features/
│     ├─ Adoption/
│     ├─ Home/
│     ├─ Backpack/
│     ├─ Growth/
│     └─ Settings/
├─ Shared/
│  ├─ Domain/          # GameState、Pet、GrowthEvent
│  ├─ StateEngine/     # 时间投影、互动规则、动作判定
│  ├─ Persistence/     # App Group PetRepository
│  ├─ UseCases/        # 查询、互动、购买的应用用例
│  ├─ WidgetBridge/    # Widget 刷新端口与 WidgetKit 实现
│  ├─ Intents/         # Feed/Pet/Play AppIntent
│  ├─ Routing/         # pocketpal:// 深链
│  └─ DesignSystem/    # 颜色、字体、间距、组件
├─ Widget/
│  ├─ PocketPalWidget.swift
│  ├─ TimelineProvider.swift
│  └─ Views/           # Small/Medium/Large
├─ Resources/
│  └─ Assets.xcassets
└─ Tests/
   ├─ StateEngineTests/
   ├─ PersistenceTests/
   ├─ UseCaseTests/
   └─ IntentTests/
```

架构约束：

- 领域模型和 StateEngine 不依赖 SwiftUI、WidgetKit、App Intents 或具体持久化实现。
- App、Widget 和 App Intent 只能调用 Use Case，不得直接修改 `GameState` 或调用具体 Repository。
- `PetRepository`、`WidgetRefreshNotifying` 和 `DateProviding` 由共享领域层定义协议，具体实现仅在组合入口装配。
- 查询 Use Case 只读取事实状态并做纯投影，不写回衰减结果，也不触发 Widget 刷新。
- 修改 Use Case 必须按“读取 → 投影 → 校验 → 更新 → 保存 → 通知”执行；只有保存成功后才能通知 Widget 刷新。
- MVP 保持单工程和共享源码，不引入 Tuist、Clean Architecture 多 Target 或每 Feature 五 Target；后续规模达到真实复用需求时再拆本地 Swift Package。

### 9.3 App 与 Widget 共享

- App 和 Widget Extension 启用同一个 App Group，例如 `group.<team>.pocketpal`。
- `PetRepository` 从共享容器读取 `game-state.json`，用 Codable 编解码。
- App 前台互动与 App Intent 都走相同的修改 Use Case：读取 → 时间结算 → 校验 → 应用动作 → 原子保存 → 写历史。
- 领域层通过 `WidgetRefreshNotifying` 请求刷新；生产实现封装 `WidgetCenter.shared.reloadTimelines(ofKind:)`，测试使用 Spy/No-op 实现。
- 保存成功后通知恰好一次；校验失败或保存失败时不得通知。查询、Timeline 渲染和 Preview 不得通知，避免刷新循环。
- 共享代码通过 target membership 复用；后续规模变大时可迁移为本地 Swift Package，不改变上层接口。

### 9.4 Widget 时间线

- Widget Extension 不运行常驻计时器，也不假设系统会准点刷新。
- TimelineProvider 通过查询 Use Case 读取一次事实状态，用 StateEngine 为未来 12 小时生成关键状态转换时间点的投影快照；必要时补充低频兜底条目，不采用固定 15 分钟轮询。
- 发生 App/App Intent 写入后主动请求重载；正常时间变化由时间线推进。
- 生产设备的刷新由系统预算和可见性共同决定，因此验收看“下一次系统渲染是否正确”，不承诺持续实时动画。

### 9.5 App Intents 与深链

- `FeedPetIntent`、`PetPetIntent`、`PlayPetIntent` 均默认不打开 App，在 `perform()` 中调用共享 InteractionService。
- Widget 用 `Button(intent:)` 执行动作；按钮完成后由系统重新请求时间线。
- 无食物、未领养或需要完整管理时，Widget 根据快照把相应位置渲染成 `Link`。
- 深链：`pocketpal://adopt`、`pocketpal://home`、`pocketpal://backpack`、`pocketpal://growth`。

### 9.6 可测试性

- StateEngine 是无 UI、无 I/O 的纯函数，时间通过可注入 Clock/DateProvider 控制。
- Repository 用协议隔离，单元测试使用内存实现；共享容器实现单独做读写和损坏恢复测试。
- Use Case 测试使用固定 Clock、内存 Repository 和 Widget 刷新 Spy，验证成功保存后恰好刷新一次、失败不刷新、查询不刷新也不写回。
- App Intent 测试验证动作结果和失败时不产生部分写入。
- SwiftUI Preview 覆盖浅色/深色、三种 Widget family、未领养/饥饿/开心/睡觉/错误状态。

### 9.7 无本地 Mac 的验证策略

- 使用可复现的 `project.yml` 和 XcodeGen 2.46.0 生成 Xcode 工程，避免在 Windows 上手工维护脆弱的 `.pbxproj`。
- GitHub Actions 使用标准 macOS runner 生成工程、编译 App 与 Widget Extension、执行单元测试和 App UI 冒烟测试，并上传 `.xcresult`、日志与截图。
- 增加仅在 Debug 构建出现的 Widget Preview Harness，把小/中/大布局和典型状态渲染在 App 内，允许 CI 生成可下载截图。
- CI 能证明“能生成、能编译、规则正确、App 主流程可跑”，但不能证明 SpringBoard 真实添加 Widget、主屏幕按钮触发或系统刷新调度正确。
- 最终 Widget 人工验收使用一次短期远程 Mac 或借用 Mac；若要在自己的 iPhone 上通过 TestFlight 验证，还需要 Apple Developer Program 和签名配置。

## 10. 视觉方向

- 关键词：明亮、治愈、圆润、干净二维插画、夸张但不吵闹。
- 宠物：头身比约 1:1，大眼睛，短四肢，轮廓圆润；同一形象至少准备闲逛、睡觉、找食物、吃饭、被摸、玩耍、难过 7 组姿态。
- 色彩：奶油黄、薄荷绿、蜜桃粉、天空蓝为基础马卡龙色；深色模式改为低亮度彩色面，不把纯白背景简单反相成纯黑。
- 小组件：背景只承担空间和情绪，不堆装饰；宠物永远是第一视觉层级，状态第二，操作第三。
- 图标与文字并用；心情和饥饿不能只靠颜色区分。
- 使用系统文本样式，不锁死字号；在极大字号下允许减少装饰和改为更紧凑的信息布局，但不得隐藏核心状态或唯一操作。
- 原型阶段使用原创或明确可授权的插画资源，不复制竞品宠物形象。

## 11. 非功能需求

| 类别 | 要求 | 优先级 |
|---|---|---|
| 性能 | 本地冷启动后 1 秒内出现可交互首屏为目标；单次状态计算与保存测试目标 <100ms | P0 |
| 安全 | 不含账号、密钥、网络接口；所有数值修改均经统一规则层校验 | P0 |
| 隐私 | 宠物名和互动记录只保存在本机 App Group；不采集分析数据 | P0 |
| 兼容性 | iPhone、iOS 17.0+；支持 `.systemSmall/.systemMedium/.systemLarge` | P0 |
| 可靠性 | 原子保存、备份恢复、schemaVersion；写入失败不允许半扣库存或金币 | P0 |
| 可访问性 | VoiceOver 标签/提示、Dynamic Type、深色模式、按钮最小可触区域、非纯颜色表达 | P0 |
| 本地化 | 首版只交付简体中文，但所有用户文案使用可本地化资源键 | P1 |

## 12. 分阶段开发与运行测试

> 已确认当前没有本地 Mac。开发期间以 GitHub Actions 的 macOS runner 作为编译和自动测试门禁；涉及真实主屏幕 Widget 的最终验收，集中到一次短期远程 Mac 人工测试。纯 Windows 不能完整替代这一步。

### 阶段 A：工程骨架与共享领域层

- 交付：可复现工程定义、App/Widget targets、App Group 配置、GameState、StateEngine、Repository 协议、单元测试和 macOS CI。
- Windows 验证：推送代码后查看 CI；必须生成 Xcode 工程、编译两个 target、运行状态时间投影和三种互动规则测试，并上传 `.xcresult`。

### 阶段 B：领养与 App 家园

- 交付：领养、命名、家园、三种 App 内互动和本地保存。
- Windows 验证：CI 在 iOS Simulator 执行领养、重启恢复和三种 App 内互动的 UI 冒烟测试，并上传关键页面截图；测试时钟验证经过数小时后的饥饿和心情。

### 阶段 C：三尺寸 Widget 展示

- 交付：小/中/大 Widget、placeholder、三种尺寸布局、时间线投影。
- Windows 验证：CI 编译 Widget Extension，并通过 Debug Preview Harness 输出三种尺寸、深浅模式和最大辅助字号截图。
- 最终人工验证：在远程 Mac 的 iOS Simulator 主屏幕添加三种尺寸，确认 Widget Gallery、真实容器边距和可读性。

### 阶段 D：App Intents 与深链

- 交付：喂食、抚摸、玩耍 App Intent；无库存转背包；WidgetCenter 重载；页面深链。
- Windows 验证：CI 编译三个 App Intent，直接测试共享规则、原子写入、冷却和深链路由；失败操作不得部分写入。
- 最终人工验证：在远程 Mac 关闭 App 后从中号/大号 Widget 触发每个动作；重新打开 App 核对数值和历史；把库存降为 0，验证喂食位置跳转背包。

### 阶段 E：背包、成长记录与收尾

- 交付：金币购买食物、记录列表、清空、改名、数据重置、VoiceOver 文案和视觉状态。
- Windows 验证：CI 完成 App 内“玩耍赚金币 → 买饼干 → 成长页回看”流程，并输出深色模式、最大字号与无障碍标识检查结果。
- 最终人工验证：补测“Widget 喂食”和 VoiceOver 实际朗读顺序。

### 阶段 F：审查与最终验收

- 交付：代码审查、缺陷修复、单元测试、UI 冒烟测试和运行说明。
- 远程 Mac 测试：在未连接调试器的模拟器验证 Widget 刷新、三尺寸布局、App 未前台运行时的按钮和深链。
- 可选真机测试：若后续加入 Apple Developer Program，则通过 TestFlight 安装到 iPhone，验证锁屏交互限制、生产刷新节奏和 App Group 签名配置。

## 13. 决策、假设与待确认

### 13.1 已确认决策

| 编号 | 决策 | 状态 |
|---|---|---|
| DEC-001 | MVP 采用 iOS 17+、奶油团子猫、非惩罚养成、单一食物金币闭环 | 2026-08-24 用户确认 |
| DEC-002 | 当前无本地 macOS + Xcode 环境；开发期使用云端 macOS CI，最终集中做一次远程 Mac 人工验收 | 2026-08-24 用户确认 |
| DEC-003 | 只参考 YuGeonHui/Tamagotchi 的工程分层：纯状态策略、Use Case、Repository、Widget 刷新端口和相应测试；不采用其 Emoji UI、iOS 18 门槛、数值规则、SwiftData、Tuist 或重型微模块 | 2026-08-25 用户确认 |

### 13.2 默认假设

| 编号 | 假设 | 依据 | 错误风险 |
|---|---|---|---|
| ASM-001 | 最低支持 iOS 17.0 | App Intents 交互式 Widget 从 iOS 17 起可用 | 若要求兼容 iOS 16，需要把直接互动降级为打开 App |
| ASM-002 | 首版宠物是奶油色团子猫 | 用户只指定“一只动物”，未指定物种 | 视觉资产需重画，但领域和交互代码不受影响 |
| ASM-003 | 采用非惩罚养成：不会死亡、生病或离家 | “明亮、治愈”和最小版本导向 | 若要硬核养成，状态机、文案和通知范围会扩大 |
| ASM-004 | 背包只保留一种消耗食物和一种可重复玩具 | 满足背包可见与金币闭环，同时控制范围 | 若要多道具，需要新增物品效果、分类和商店规则 |
| ASM-005 | 工作名称和 Bundle ID 可后续替换 | 用户未提供品牌名和开发者 Team ID | 签名、App Group 和 URL Scheme 最终需统一重命名 |
| ASM-006 | 最终人工 Widget 验收可使用短期远程 Mac 服务或临时借用设备 | 用户没有本地 Mac，但真实 SpringBoard Widget 无法仅靠 CI 完整验证 | 如果始终没有可交互 Mac，只能交付“自动测试通过、真实 Widget 未人工验收”的版本 |

### 13.3 待确认问题

| 编号 | 问题 | 是否阻塞 | 备注 |
|---|---|---:|---|
| Q-003 | 产品正式名称和 Bundle ID 是什么？ | No | 开发可先用工作名和占位标识 |

## 14. 完成定义

- [x] 用户已确认 MVP 基线和无本地 Mac 的验证路径。
- [ ] 所有 P0 范围和 AC-001 至 AC-013 已通过。
- [ ] iPhone iOS 17+ 模拟器能完成首次领养和完整互动闭环。
- [ ] 三种 Widget family 均能添加、展示并与 App 共享同一状态。
- [ ] 中号和大号 Widget 的三种动作在 App 未前台运行时也能按系统允许的方式执行。
- [ ] 深色模式、VoiceOver 和最大辅助字号回归通过。
- [ ] GitHub Actions 的 macOS runner 已生成工程、编译 App 与 Widget Extension、执行自动测试并上传证据。
- [ ] 在远程或借用 Mac 上完成人工 Widget 验收；若未完成，交付状态必须明确标记为“真实 Widget 未人工验收”。

## 15. 依据与竞品观察

- Apple 说明交互式 Widget 可用 `Button`/`Toggle` 配合 App Intents 执行动作，且 Widget Extension 与 App 是不同进程：[Adding interactivity to widgets and Live Activities](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)。
- Apple 建议用 App Group 让 App 与 Extension 访问共享容器：[Configuring app groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)。
- Apple 明确 Widget 刷新受系统预算控制，常见日预算约 40–70 次，时间线日期也不保证精确触发：[Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)。
- Widgetable 已把宠物、共养和社交做成大而全产品；首版不应跟着堆功能：[Widgetable App Store](https://apps.apple.com/us/app/widgetable-besties-couples/id1641107226)。
- Pixel Pals 已覆盖多动物、互动 Widget、小游戏和付费内容，但其核心视觉是用户明确排除的像素风：[Pixel Pals App Store](https://apps.apple.com/us/app/pixel-pals-widget-pet-game/id6443919232)。
- WidPet 直接标注 iOS 17+ Widget 互动，验证了本方案的平台基线和核心交互形态：[WidPet App Store](https://apps.apple.com/us/app/widpet-pet-on-widget/id6466376612)。
- YuGeonHui/Tamagotchi 展示了纯状态策略、Repository/Use Case 分层、App Group 共享和保存成功后刷新 Widget 的实现方式；本项目只吸收这些工程原则，不复制其源码、视觉或产品范围：[Tamagotchi GitHub](https://github.com/YuGeonHui/Tamagotchi)。
- 该参考仓库当前仅有两项状态、喂食/玩耍两种互动和小/中两种 Widget，且无可识别的开源许可证，因此不能替代本 Spec，也不得直接复制代码或资源：[GitHub 关于无许可证仓库的说明](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)。
