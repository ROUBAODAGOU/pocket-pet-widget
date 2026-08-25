# PocketPal

PocketPal 是一个以 iPhone 主屏幕小组件为核心触点的本地虚拟宠物原型。Phase 1 的可复现 Xcode 工程与云端验证骨架已经完成，并已在 GitHub Actions 的 macOS runner 上通过真实编译与模拟器测试。

## 当前验证状态

- 仓库：<https://github.com/ROUBAODAGOU/pocket-pet-widget>
- 成功运行：<https://github.com/ROUBAODAGOU/pocket-pet-widget/actions/runs/32816753654>
- 验证提交：`58aef4e17473e9744ca827095c879b15fd7cf4c9`
- 结果：XcodeGen 工程生成成功；App 与 Widget Extension 编译成功；Unit Tests 1/1、UI Tests 1/1 通过。
- 制品：`pocketpal-ios-verification`，包含 `PocketPal.xcresult` 与 `xcodebuild.log`。

## 没有 Mac 时怎么验证

1. 打开本仓库的 **Actions** 页面，选择 **iOS CI**。
2. 查看最新的 `main` 分支运行，或手动点击 **Run workflow** 复跑。
3. 工作流会在 GitHub 的 macOS 26 runner 上安装固定版本 XcodeGen、生成 Xcode 工程、启动 iPhone Simulator、编译 App 与 Widget Extension，并运行测试。
4. 任务结束后下载 `pocketpal-ios-verification`，其中包含 Xcode 测试结果和同时收集标准输出、标准错误的构建日志。

绿色 CI 只能证明工程可生成、可编译且自动测试通过。真实主屏幕添加 Widget、点击 App Intent 按钮和系统刷新节奏，仍需要在可远程操作的 Mac 上做最终人工验收。

## 在 Mac 上运行

```sh
xcodegen generate
open PocketPal.xcodeproj
```

在 Xcode 中选择 `PocketPal` scheme 和任一 iOS 17+ iPhone Simulator，然后运行。Phase 1 只显示工程状态页；后续阶段才加入领养和宠物互动。

## 当前标识

- Bundle ID：`com.example.PocketPal`
- Widget Bundle ID：`com.example.PocketPal.Widget`
- App Group：`group.com.example.pocketpal`
- URL Scheme：`pocketpal://`

这些是原型占位标识。进入签名、真机或 TestFlight 前，必须替换为你自己的唯一标识并保持 App 与 Widget 的 App Group 完全一致。
