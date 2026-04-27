# Stash 功能清单

类 [pasteapp.io](https://pasteapp.io) 的 macOS 剪贴板管理器。自用、不上架 App Store、不做云同步。
最低系统 macOS 14 Sonoma。语言 Swift / SwiftUI + AppKit interop。

迭代节奏:v0.1 → v0.2 → v0.3 → v0.4,每版独立可运行可测。完成项请把 `[ ]` 改成 `[x]` 并在版本标题加完成日期。

---

## v0.1 — 最小可用核心 (MVP) ✅ 2026-04-28

**目标**: 跑通 "复制 → 唤起 → 选 → 粘贴" 主链路,只支持最常用 3 种类型(text / image / URL)。

> Done when: 在任何 app 里复制一段文字或一张图,按 ⌘⇧V 唤起浮窗,看到刚复制的卡片在最前面,按 Enter 或 ⌘1 粘贴回原 app。

- [x] **F-01** Xcode SwiftUI macOS app 工程脚手架(`Stash.xcodeproj`,`xcodegen` 生成)
- [x] **F-02** 菜单栏图标 + 退出菜单(`MenuBarExtra`)
- [x] **F-03** 全局热键 `⌘⇧V` 唤起 / 隐藏浮窗(HotKey SPM 包)
- [x] **F-04** 无边框玻璃浮窗(`NSPanel` + `.background(.ultraThinMaterial)`,底部贴边)
- [x] **F-05** `NSPasteboard` 轮询(0.5s,`changeCount` diff)
- [x] **F-06** 类型识别:plain text / image (PNG/JPEG) / URL
- [x] **F-07** SwiftData `@Model Clip` 持久化(text 内联;image 落盘 + 路径引用)
- [x] **F-08** `BlobStore` — 图片落盘到 `~/Library/Application Support/Stash/Blobs/{uuid}.png`
- [x] **F-09** 横向卡片画廊(`ScrollView(.horizontal)`,3 种类型基础渲染)
- [x] **F-10** 键盘 `← →` 切换、`Enter` 粘贴、`Esc` 关闭(`.onKeyPress`)
- [x] **F-11** `⌘1` – `⌘9` 快捷粘贴前 9 项
- [x] **F-12** 模拟 `⌘V` 粘贴到唤起前的前台 app(`CGEventCreateKeyboardEvent` + `kCGHIDEventTap`)
- [x] **F-13** Accessibility 权限缺失引导(检测 + 弹窗 + 跳系统设置)
- [x] **F-14** 历史去重(`SHA256` hash,连续相同不重复存)

---

## v0.2 — 类型完善 + 搜索过滤 ✅ 2026-04-28

**目标**: 支持全部 8 种类型并提取 metadata,搜索 / 过滤 / Quick Look 全部可用。

> Done when: 复制富文本、图片、PDF、链接、hex 颜色、SQL 代码、地址 → 卡片渲染对路;搜索框输入关键字命中高亮;`Space` 长按出大图。

- [x] **F-15** 类型扩展:RTF / HTML / file URL / color / code / address
- [x] **F-16** `NSDataDetector` 识别 URL / 地址 / 电话(从 plain text 升级类型)
- [x] **F-17** 链接 metadata: `LPMetadataProvider` 抓 title / favicon
- [x] **F-18** 图片 metadata: 尺寸 + 主色板(CoreImage `kCIAttributeTypeColor` 取 4 色)
- [x] **F-19** 颜色识别:正则匹配 `#RRGGBB` / `rgb(…)` / `oklch(…)`,生成 RGB+HSL 副信息
- [x] **F-20** 代码语言推断(扩展名提示 + 关键字启发式:SQL / TypeScript / Shell / JSON / Python …)
- [x] **F-21** 实时搜索(标题 + 正文 + 来源 app 字段;debounce 120ms)
- [x] **F-22** 类型过滤胶囊(All / Text / Image / Link / Code / Color / File)
- [x] **F-23** 命中高亮(`AttributedString.foregroundColor` + `.backgroundColor`)
- [x] **F-24** 时间分组标签(Just now / Today / Yesterday / Last week / Older)
- [x] **F-25** `Space` 长按 Quick Look 大图预览(松开关闭)
- [x] **F-26** `⇧⌘V` 粘贴为纯文本(剥格式)
- [x] **F-27** `⌘F` 焦点跳搜索框

---

## v0.3 — 组织能力 ✅ 2026-04-28

**目标**: 用户能自建分类(Pinboards),Pin / 删除 / 编辑 / 移动剪贴。

> Done when: 创建 "Engineering" 和 "Design refs" 两个 Pinboard,把代码片段拖进 Engineering、把图片拖进 Design refs;`⌘P` 置顶常用项;右键菜单完整可点。

- [x] **F-28** `Pinboard` SwiftData 模型(id / name / icon / accent / order)
- [x] **F-29** 侧栏 Pinboards 列表(All / 用户自建 / + New Pinboard)
- [x] **F-30** 新建 / 重命名 / 删除 Pinboard
- [x] **F-31** `⌘P` 置顶 / 取消置顶(`Clip.pinnedAt: Date?`)
- [x] **F-32** 置顶项排到画廊最前
- [x] **F-33** `⌫` / `Delete` 删除剪贴
- [x] **F-34** 右键菜单:Paste / Copy again / Pin / Move to Pinboard… / Edit / Delete
- [x] **F-35** 编辑模式 — 纯文本可改(图片/文件不可改,只能 rename)
- [x] **F-36** `⌘[` `⌘]` 切换 Pinboard
- [x] **F-37** 拖拽卡片 → Pinboard 归类(`.draggable` / `.dropDestination`)
- [x] **F-38** 删除二次确认(只对 Pin 过的项要确认)

---

## v0.4 — 偏好设置 + 打磨 ✅ 2026-04-28

**目标**: 偏好窗口三栏完整,自定义热键 / 容量 / 外观全部可调,可打 DMG 自分发。

> Done when: 打开 Preferences 改全局热键 → 立即生效;改历史上限 100 → 旧的多余项被裁掉;深/浅色跟随系统切换;运行 `./scripts/build-dmg.sh` 产出 `Stash.dmg`。

- [x] **F-39** Preferences 独立窗口(`Settings` scene 或 `NSWindowController`),3 个 tab
- [x] **F-40** General tab:开机启动(`SMAppService`)、菜单栏图标显隐、历史上限选项(100/500/1000/无限)、提示音开关
- [x] **F-41** Shortcuts tab:全局热键录制框 + 内部快捷键全表(只读展示)
- [x] **F-42** Appearance tab:深/浅色(跟随系统/强制)、玻璃模糊度(slider 10-80)、卡片密度(compact/default/cozy)、壁纸主题(warm/cool/mono)
- [x] **F-43** 历史 LRU 清理(超上限时优先删最旧未 pinned)
- [x] **F-44** 失焦自动隐藏(可在 Preferences 关闭)
- [x] **F-45** 全部偏好持久化(`UserDefaults` + `@AppStorage`)
- [ ] **F-46** 应用图标(取设计稿橙色调,1024×1024 + 全套 mac size)
- [x] **F-47** `scripts/build-dmg.sh` — Xcode Archive → `create-dmg` 一键产 DMG
- [x] **F-48** Developer ID 自签(自用,跳过公证)

---

## 进度跟踪

| 版本 | 状态 | 完成日期 | git tag |
| --- | --- | --- | --- |
| v0.1 | ✅ 已完成 | 2026-04-28 | v0.1.0 |
| v0.2 | ✅ 已完成 | 2026-04-28 | v0.2.0 |
| v0.3 | ✅ 已完成 | 2026-04-28 | v0.3.0 |
| v0.4 | ✅ 已完成 | 2026-04-28 | v0.4.0 |

每版交付时:
1. 勾选所有 F-xx
2. 跑 test_plan.md 对应版本的 checklist
3. 填上完成日期 + `git tag v0.x`
