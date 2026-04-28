# Stash Bug 列表

Bug ID 自增，每条关联测试用例和功能项。状态：`open` / `fixed` / `wontfix`。

---

## P0 — 阻塞级

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-001 | 键盘完全失效：←→/Enter/Esc/⌘1-9 均无响应。`.onKeyPress` 在 NSPanel+NSHostingView 中无法正确接收键盘事件 | F-10, F-11, F-12, F-25, F-26, F-27, F-31, F-33, F-36 | UI-03, UI-04, UI-05, UI-06, UI-09, UI-10, UI-11, UI-14, UI-15, UI-16, M-08 | fixed |
| BUG-002 | UI 响应速度过慢：所有按钮/搜索/编辑点击后有明显延迟，疑似 NSEvent monitor 或 .onKeyPress 链阻塞主线程 | 全局 | M-18 | fixed |

## P1 — 功能错误

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-003 | ClipParser HTML 优先级截获：复制 URL / 颜色值 / 富文本时被归为 HTML 类型，而非 link/color/rtf | F-06, F-15, F-19 | U-02, U-16, U-17, M-05, M-11, M-13 | fixed |
| BUG-004 | Space 长按预览失效：搜索框始终持有焦点，Space 键被 TextField 拦截输入空格而非触发预览 | F-25 | UI-09 | fixed |
| BUG-005 | ⌘F 搜索焦点无法测试：焦点始终在搜索框中 | F-27 | UI-11 | fixed |
| BUG-006 | 壁纸主题切换无效果：Appearance tab 切换 warm/cool/mono 后浮窗背景无变化 | F-42 | UI-22 | fixed |

## P2 — 交互问题

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-007 | Preferences 切到第2个 tab 后 tab 栏消失 | F-39 | UI-19 | fixed |
| BUG-008 | 拖拽卡片到 Pinboard 不工作 | F-37 | UI-17, M-20 | fixed |
| BUG-009 | 右键删除 pinned 卡片无二次确认弹窗（仅键盘删除有确认） | F-38 | UI-18 | fixed |
| BUG-010 | 卡片选中时自动滚动到水平居中，应为左对齐或无自动滚动 | F-09 | UI-02 | fixed |
| BUG-011 | Pinboard rename 时输入框不自动聚焦 | F-30 | - | fixed |

## P3 — 缺失功能

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-012 | F-13 Accessibility 启动引导 UI 缺失（检测逻辑有，但无首次启动弹窗引导） | F-13 | M-07, M-29 | fixed |
| BUG-013 | F-41 热键录制仅 UI 占位，无实际录键逻辑 | F-41 | U-37, U-38, UI-21, M-24 | fixed |
| BUG-014 | F-46 应用图标未实现，Assets.xcassets 为空 | F-46 | M-29 | fixed |

## P4 — 新需求

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-015 | 卡片长宽比需改为 1:1，上下留有空间 | F-09 | UI-02 | fixed |
| BUG-016 | 数据保留策略：非 Pinboard 的 clip 保留 90 天后自动删除，Pinboard 内的永久保留 | F-43 | M-26 | fixed |

## P1 — 功能错误（v0.5.0 第二轮）

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-017 | 菜单栏图标点击无法唤出偏好设置：Settings scene 在 MenuBarExtra-only App 中不工作 | F-39 | UI-19 | fixed |
| BUG-018 | 卡片选中时自动滚动到 .leading，应保持原位不滚动 | F-09 | UI-02 | fixed |
| BUG-019 | 右箭头键视觉跳页：selectNext 正确但 scroll-to-leading 导致视觉翻页效果 | F-10 | UI-03 | fixed |
| BUG-020 | 面板右上角齿轮按钮点击无反应（与 BUG-017 同因） | F-39 | UI-19 | fixed |
| BUG-024 | 偏好设置窗口内控件不可点击（NSWindow 管理方式 + contentShape 缺失） | F-39 | UI-19 | fixed |

## P2 — 交互问题（v0.5.0 第二轮）

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-021 | 添加 Pinboard 时输入框不自动聚焦，缺少 @FocusState | F-30 | - | fixed |
| BUG-022 | 输入新 Pinboard 名字时崩溃：TextField 在 isAddingPinboard 变 false 期间仍在 responder chain | F-30 | - | fixed |
| BUG-023 | 侧栏布局间距不一致：PINBOARDS header padding 12px 与 All Clips 14px 不对齐 | F-29 | UI-17 | fixed |

## v0.5.0 第三轮（二次复查发现的回归 / 漏修）

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-012R | Accessibility 启动引导回归：第二轮改动把 NSAlert 整段删掉了，恢复 | F-13 | M-07, M-29 | fixed |
| BUG-004R | Space 键修过头：handleKey 无条件吞 Space，搜索框/rename 输入框打不出空格。补 isEditingTextField 判断后放行 | F-25 | UI-09 | fixed |
| BUG-014R | menu-icon.imageset 加了但 MenuBarExtra 仍用 systemImage，资源未生效 | F-46 | M-29 | fixed |
| BUG-011R | rename 焦点时序：editingPinboard 与 isEditingFocused 同步设置，TextField 还没渲染 focus 落空。改 DispatchQueue.main.async | F-30 | - | fixed |
