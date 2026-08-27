# PocketPal

PocketPal 是一个以 iPhone 主屏幕小组件为核心触点的本地虚拟宠物原型。Phase 1 的可复现 Xcode 工程与云端验证骨架、Phase 2 的宠物状态引擎与共享持久化、Phase 3 的领养与 App 内互动闭环，以及 Phase 4 的三尺寸 Widget 与时间线展示已经完成，并已在 GitHub Actions 的 macOS runner 上通过真实编译与 iPhone 模拟器测试。

## 当前验证状态

- 仓库：<https://github.com/ROUBAODAGOU/pocket-pet-widget>
- Phase 4 成功运行：<https://github.com/ROUBAODAGOU/pocket-pet-widget/actions/runs/33054538094>
- Phase 4 验证提交：`43fb6746b624e67b8739a114fba7d645afd30227`
- 结果：XcodeGen 工程生成成功；App 与 Widget Extension 编译成功；Unit Tests 53/53、UI Tests 7/7 通过，0 失败，日志以 `TEST SUCCEEDED` 结束。
- 制品：`pocketpal-ios-verification` 包含 `PocketPal.xcresult` 与 `xcodebuild.log`；`ui-screenshots` 包含 33 张 App 与三尺寸 Widget Preview Harness 截图。
- Windows 本地证据：`E:\PocketPal-CI-Evidence\run-33054538094-green`。
- 独立审查与人工截图复核均通过，0 个 HIGH/MEDIUM 遗留问题。

## 没有 Mac 时怎么验证

1. 打开本仓库的 **Actions** 页面，选择 **iOS CI**。
2. 查看最新的 `main` 分支运行，或手动点击 **Run workflow** 复跑。
3. 工作流会在 GitHub 的 macOS 26 runner 上安装固定版本 XcodeGen、生成 Xcode 工程、启动 iPhone Simulator、编译 App 与 Widget Extension，并运行测试。
4. 任务结束后下载 `pocketpal-ios-verification`，其中包含 Xcode 测试结果和构建日志；下载 `ui-screenshots` 可直接查看模拟器页面。

绿色 CI 证明工程可生成、App 与 Widget Extension 可编译、时间线与三尺寸预览可自动测试。真实主屏幕添加 Widget、点击 App Intent 按钮和系统刷新节奏，仍需要在可远程操作的 Mac 上做最终人工验收。

## 在 Mac 上运行

```sh
xcodegen generate
open PocketPal.xcodeproj
```

在 Xcode 中选择 `PocketPal` scheme 和任一 iOS 17+ iPhone Simulator，然后运行。首次启动进入领养页；命名后进入家园，可查看宠物状态并执行喂食、抚摸和玩耍。当前 Widget Extension 已包含小、中、大三种尺寸及时间线展示；下一阶段将把三个操作位置接入 App Intents，并实现页面深链。

## 当前标识

- Bundle ID：`com.example.PocketPal`
- Widget Bundle ID：`com.example.PocketPal.Widget`
- App Group：`group.com.example.pocketpal`
- URL Scheme：`pocketpal://`

这些是原型占位标识。进入签名、真机或 TestFlight 前，必须替换为你自己的唯一标识并保持 App 与 Widget 的 App Group 完全一致。
