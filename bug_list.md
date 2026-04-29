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

## v0.5.0 第四轮（交互打磨 + 粘贴修复）

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-025 | 粘贴不回前台应用：选中卡片按 Enter 后内容写入剪贴板，但未粘贴回前台应用输入框。根因：未释放 Stash 焦点 + 未按 PID 发送 CGEvent | F-12 | M-08 | fixed |
| BUG-026 | ⌘1-9 快捷粘贴未激活前台应用：直接调 PasteSimulator.simulatePaste()，没有关闭面板、没有激活前台应用、没有延迟 | F-11 | UI-04 | fixed |

## v0.5.0 第五轮（用户实测回归）

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-027 | 设置页标题栏渲染为线框样式：fullSizeContentView 未配置，缺少透明标题栏 + 实色背景 | F-39 | UI-19 | fixed |
| BUG-028 | 空白状态 UI 仅在有文案的区域显示背景色，未撑满画廊全宽全高 | F-09 | UI-02 | fixed |
| BUG-029 | 卡片编辑点击后应用卡死：NSPanel 不支持 SwiftUI .sheet()，改用自定义 overlay | F-35 | M-17 | fixed |
| BUG-030 | 图片类型卡片将 footer 挤出卡片边界：cardBody 用 maxHeight:.infinity 嵌套导致布局协商失败，改用 cardSize - footerHeight 显式计算 | F-09 | UI-02 | fixed |
| BUG-031 | 卡片 footer 背景色不填满卡片宽度：.background() 在 .padding() 之后导致左右留白 | F-09 | UI-02 | fixed |
| BUG-032 | Finder 复制文件检测失败：Finder 使用 file reference URL (file:///.file/id=…) 而非路径 URL，且放入文件图标 TIFF 数据截获图片检测 | F-06, F-15 | U-02, M-05 | fixed |
| BUG-033 | Finder 复制图片文件被归为 File 类型：需要在文件 URL 检测中读取图片扩展名并分类为 Image | F-06 | U-02 | fixed |
| BUG-034 | SwiftData schema 变更后 Pinboard 数据丢失：loadFromContext 用 try? 静默吞错，ModelContainer 创建失败直接 fatalError 无降级 | F-28 | M-20 | fixed |
| BUG-035 | Pin Picker 底栏背景不填满弹窗宽度：footer HStack 缺少 .frame(maxWidth:.infinity) | F-31 | UI-17 | fixed |
| BUG-036 | Pin Picker 每行右侧显示多余序号 1/2/3…：键盘导航已高亮选中行，序号冗余 | F-31 | UI-17 | fixed |
| BUG-037 | All Clips 视图下 Pin badge 不显示：pinColor(for:) 中 activePinboardId == nil 直接返回 nil | F-52 | UI-17 | fixed |
| BUG-038 | Appearance 设置页 Theme 选项多余：当前仅暗色模式，无其他主题可选 | F-42 | UI-22 | fixed |
| BUG-039 | 首次启动顺序错误：应先打开设置页再弹出辅助功能授权弹窗 | F-13 | M-07 | fixed |

## v0.6.x（搜索态粘贴回归）

| Bug ID | 描述 | 关联功能 | 关联测试 | 状态 |
|---|---|---|---|---|
| BUG-040 | 搜索后选中卡片按 Enter 不粘贴：搜索框聚焦时 handleKey 直接 return false 让 Enter 流到 TextField 被吞掉。仅当 firstResponder 的 fieldEditor 属于搜索框（placeholder == "Search clips..."）时拦截 Enter 触发粘贴，避免影响 Pinboard 重命名提交 | F-12, F-27 | UI-05, UI-11 | fixed |
