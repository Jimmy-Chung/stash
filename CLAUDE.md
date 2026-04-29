# Stash — macOS 剪贴板管理器

类 [pasteapp.io](https://pasteapp.io) 的本地剪贴板管理工具。Swift / SwiftUI + AppKit interop。最低系统 macOS 14 Sonoma。自用,不上架 App Store,不做云同步。

## 项目文档(必读)

- [`feat_list.md`](./feat_list.md) — 完整功能清单,按 v0.1 / v0.2 / v0.3 / v0.4 四个迭代版本组织,每项有 `F-xx` ID。新增 / 修改功能必须先在这里登记。
- [`bug_list.md`](./bug_list.md) — **Bug 列表**,按优先级 P0~P4 分级,每条关联功能 ID 和测试用例 ID。修 bug 必须先在这里登记并标记状态。
- [`test_plan.md`](./test_plan.md) — 测试用例清单。单元(`U-xx`)/ UI 自动化(`UI-xx`)/ 手工集成(`M-xx`)三层。功能实现完跑对应 ID 的用例。
- [`git-workflow.md`](./git-workflow.md) — **本项目 Git 工作流程,所有提交 / 分支 / 发布动作必须严格遵守**。要点:
  - 分支名 `feat-vx.y.0`(需求)/ `feat-vx.y.z`(修复)
  - 每个 commit 必须 `feat(F-xx): <描述>` 格式带 feat_id
  - 单功能完成 → 跑对应测试 → 通过才 commit
  - 版本完成 → 全量回归 → Jimmy 确认可发布 → 合 master + 打 tag

## UI 设计稿

- [`ui-design/`](./ui-design/) — **本项目 UI 设计文件**,Claude Design 生成的 HTML/CSS/JS 原型。**实施 Swift UI 时务必参照这里的视觉规范**(布局、间距、颜色、玻璃效果参数、卡片尺寸、动画)。
  - `Stash.html` — 入口页(在浏览器打开可看交互效果)
  - `styles.css` — 全部视觉规范(颜色、间距、动画、卡片样式、Pinboards、Preferences、Context menu …)
  - `app.jsx` — 主应用逻辑(键盘、状态、路由)
  - `card.jsx` — 卡片各类型渲染(text / code / link / image / color / file / address)
  - `preferences.jsx` — 偏好设置窗口(General / Shortcuts / Sync / Privacy 四 tab)
  - `utils.jsx` — Icon 集 / 代码高亮 / 工具函数
  - `data.js` — 示例数据(剪贴样例 / Pinboards / 类型过滤)
  - `tweaks-panel.jsx` — Claude Design 编辑模式控件(实施时不需要,可忽略)
  - `uploads/` — 用户在设计期间的圈注截图(PNG)

## 规则

- 每次发版时，Preferences（设置页）底部必须显示当前版本号（如 `v0.5.0`），从 `Info.plist` 的 `CFBundleShortVersionString` 读取。

## 当前状态

- v0.1 ~ v0.4 已完成并合并 master (tag v0.4.1)
- 当前在 `bug-v0.5.0` 分支，修复用户实测发现的 16 个 bug
- 优先级：P0(键盘+响应) → P1(类型识别) → P2(交互) → P3(缺失功能) → P4(新需求)
