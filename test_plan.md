# Stash 测试计划

测试分三层:**单元测试(XCTest)**、**UI 自动化(XCUITest)**、**手工集成验证 checklist**。每版发布前必须三层全绿。

测试用例 ID 规则:`U-xx`(unit)、`UI-xx`(automation)、`M-xx`(manual)。
关联功能项以 `[F-xx]` 标注。

---

## v0.1 验证矩阵

### 单元测试 (`StashTests/`)

| ID | Suite | Case | 关联 |
| --- | --- | --- | --- |
| U-01 | ClipParserTests | `parse(_:)` 输入纯文本字符串 → `ClipType.text` | F-06 |
| U-02 | ClipParserTests | `parse(_:)` 输入合法 https URL 字符串 → `ClipType.link` | F-06 |
| U-03 | ClipParserTests | `parse(_:)` 输入 PNG 数据 → `ClipType.image` | F-06 |
| U-04 | ClipParserTests | 空 / 仅空白字符的剪贴 → 不产生 Clip | F-05 |
| U-05 | BlobStoreTests | 写入 PNG → 读回字节完全相等 | F-08 |
| U-06 | BlobStoreTests | 删除 Clip 时关联 Blob 也被删 | F-08 |
| U-07 | DedupeHasherTests | 同一段 plain text 连续两次 hash 相同 | F-14 |
| U-08 | DedupeHasherTests | 同一张图片 bytes 两次 hash 相同 | F-14 |
| U-09 | DedupeHasherTests | 不同 case ("Hello" vs "hello")hash 不同(保留大小写) | F-14 |
| U-10 | ClipboardWatcherTests | mock pasteboard `changeCount` 不变 → 不触发 onCopy 回调 | F-05 |
| U-11 | ClipboardWatcherTests | mock pasteboard `changeCount` +1 → 触发 onCopy 一次 | F-05 |
| U-12 | ClipModelTests | SwiftData 持久化 Clip → 重启后查询能查回 | F-07 |

### UI 自动化 (`StashUITests/`)

| ID | Case | 关联 |
| --- | --- | --- |
| UI-01 | App 启动 → 菜单栏图标存在 | F-02 |
| UI-02 | 通过测试钩子触发"复制" → 唤起浮窗 → 第一张卡片选中态 | F-09 |
| UI-03 | 按 `→` 键 → 选中态移到第二张卡片 | F-10 |
| UI-04 | 按 `Enter` → 浮窗关闭 + paste 桥接函数被调用 | F-10, F-12 |
| UI-05 | 按 `Esc` → 浮窗关闭 | F-10 |
| UI-06 | 按 `⌘3` → 第三张卡片粘贴(测试桥接收到对应 clip id) | F-11 |

### 手工集成验证

- [ ] **M-01** 全局热键 ⌘⇧V 在 Safari / Notes / Terminal 三种 app 下都能唤起 [F-03]
- [ ] **M-02** 浮窗以玻璃效果显示在屏幕底部,不遮 Dock 不遮菜单栏 [F-04]
- [ ] **M-03** 在 Notes 写一段文字 → 复制 → 唤起 → 看到这段文字的卡片 [F-05, F-06, F-09]
- [ ] **M-04** 截图后(`⌘⇧4`)→ 唤起 → 看到图片缩略图卡片 [F-06, F-08, F-09]
- [ ] **M-05** 复制一个 https URL → 唤起 → 卡片识别为 link 类型 [F-06]
- [ ] **M-06** 关闭 Stash 进程后重启 → 历史完整保留 [F-07]
- [ ] **M-07** 首次启动未授权 Accessibility → 弹引导 → 跳到系统设置开关 [F-13]
- [ ] **M-08** Accessibility 已授权 → 唤起 → Enter → 真正粘贴到唤起前的 app(在 Notes 中可见) [F-12]
- [ ] **M-09** 同一段文字连续复制 3 次 → 历史只增 1 条 [F-14]
- [ ] **M-10** 多屏幕环境下,在副屏唤起 → 浮窗弹在副屏 [F-04]

---

## v0.2 验证矩阵

### 单元测试

| ID | Suite | Case | 关联 |
| --- | --- | --- | --- |
| U-13 | ClipParserTests | RTF data → `ClipType.rtf`(保留属性串) | F-15 |
| U-14 | ClipParserTests | HTML data → `ClipType.html` | F-15 |
| U-15 | ClipParserTests | `file:///path/to/foo.pdf` → `ClipType.file` | F-15 |
| U-16 | ClipParserTests | `#F4A261` → `ClipType.color`,RGB=(244,162,97) | F-19 |
| U-17 | ClipParserTests | `rgb(36, 70, 83)` → `ClipType.color` | F-19 |
| U-18 | ClipParserTests | `SELECT * FROM users` → `ClipType.code`,language=`SQL` | F-20 |
| U-19 | ClipParserTests | TS 关键字混合 → language=`TypeScript` | F-20 |
| U-20 | ClipParserTests | "548 Market St, San Francisco" → `ClipType.address`(NSDataDetector) | F-16 |
| U-21 | LinkMetadataTests | mock LPMetadataProvider → 能存 title / faviconData | F-17 |
| U-22 | ImageMetadataTests | 取色板返回 4 个颜色,且非透明 | F-18 |
| U-23 | SearchTests | 搜 "hello" 命中 title / content / app 三处 | F-21 |
| U-24 | SearchTests | 搜空字符串 → 返回完整列表 | F-21 |
| U-25 | SearchTests | 搜 "RGB" debounce 120ms 内只触发一次 query | F-21 |
| U-26 | TimeGroupingTests | "5 分钟前" → "Just now";"3 天前" → "Last week" | F-24 |
| U-27 | HighlightTests | `AttributedString` 命中段背景色 = accent | F-23 |

### UI 自动化

| ID | Case | 关联 |
| --- | --- | --- |
| UI-07 | 输入框输 "hello" → 列表只剩匹配项,且高亮命中片段 | F-21, F-23 |
| UI-08 | 点击 "Image" 类型胶囊 → 列表只剩 image 卡 | F-22 |
| UI-09 | 长按 `Space` → Quick Look 出现;松开 → 关闭 | F-25 |
| UI-10 | `⇧⌘V` 触发 paste 桥接 → 桥接收到 plain-text 标志 | F-26 |
| UI-11 | 浮窗未聚焦输入框时按 `⌘F` → 输入框获焦 | F-27 |

### 手工集成验证

- [ ] **M-11** 复制 Notion 富文本(粗体+斜体)→ Quick Look 看到属性保留 [F-15]
- [ ] **M-12** 在 Finder 复制一个 PDF → 卡片显示文件图标 + 文件名 [F-15]
- [ ] **M-13** 在 Figma 复制一个色块 → 卡片显示色卡 + RGB/HSL [F-19]
- [ ] **M-14** 复制 GitHub URL → 1-2 秒内卡片缩略图区域出现 favicon [F-17]
- [ ] **M-15** 复制 2400x1600 大图 → 主色板 4 色显示在 swatches [F-18]
- [ ] **M-16** 复制一段 SQL → 代码区有 SELECT/FROM 关键字配色 [F-20]
- [ ] **M-17** 卡片按时间分组:刚复制的在 "Just now" 组下 [F-24]
- [ ] **M-18** 50 条历史下,搜索框打字流畅(无卡顿)[F-21]

---

## v0.3 验证矩阵

### 单元测试

| ID | Suite | Case | 关联 |
| --- | --- | --- | --- |
| U-28 | PinboardTests | 新建 Pinboard → SwiftData 持久化 | F-28, F-30 |
| U-29 | PinboardTests | 删除 Pinboard → 关联 clip 的 pinboardId 置 nil(不删 clip) | F-30 |
| U-30 | PinTests | `togglePin` → `pinnedAt` 从 nil 到 Date,反向到 nil | F-31 |
| U-31 | PinTests | pinned 项排序在 unpinned 之前(同 Pinboard 内) | F-32 |
| U-32 | DeleteTests | 删除 Clip → 同时删 Blob | F-33 |
| U-33 | EditTests | 编辑 plain text → 触发新 hash + 更新 `updatedAt` | F-35 |

### UI 自动化

| ID | Case | 关联 |
| --- | --- | --- |
| UI-12 | 右键卡片 → 菜单弹出含 6 项 | F-34 |
| UI-13 | 右键 → "Pin" → 卡片右上出现 pin 角标 | F-31 |
| UI-14 | 选中卡片按 `⌘P` → pin 角标 toggle | F-31 |
| UI-15 | 选中卡片按 `⌫` → 卡片消失;再按 `⌘Z` 不可恢复(本期不做 undo) | F-33 |
| UI-16 | `⌘]` → activePinboard 切下一个 | F-36 |
| UI-17 | 拖卡片到侧栏 "Engineering" → 卡片消失,再点 Engineering 看到它 | F-37 |
| UI-18 | 删除已 pinned 项 → 弹二次确认 alert | F-38 |

### 手工集成验证

- [ ] **M-19** 新建 "Engineering" Pinboard → 侧栏出现新条目 [F-29, F-30]
- [ ] **M-20** 把 5 段代码拖到 Engineering → 切到 Engineering 看到这 5 张 [F-37]
- [ ] **M-21** 选 Engineering → ⌘] 切到下一个,⌘[ 切回 [F-36]
- [ ] **M-22** 编辑一段长文本 → 保存 → 卡片显示新内容,搜索能命中新关键字 [F-35]

---

## v0.4 验证矩阵

### 单元测试

| ID | Suite | Case | 关联 |
| --- | --- | --- | --- |
| U-34 | LRUCleanupTests | 上限 = 5,塞 6 条无 pinned → 第 1 条被删 | F-43 |
| U-35 | LRUCleanupTests | 上限 = 5,3 条 pinned + 4 条普通 → 删最旧 2 条普通 | F-43 |
| U-36 | LRUCleanupTests | 上限 = "无限" → 不裁剪 | F-43 |
| U-37 | HotKeyRecorderTests | 录到 ⌘⌥H → parts 顺序 = ["⌘","⌥","H"] | F-41 |
| U-38 | HotKeyRecorderTests | 单修饰键不算合法记录(至少 1 修饰 + 1 按键) | F-41 |
| U-39 | LaunchAtLoginTests | toggle on → `SMAppService.mainApp.status` 报已注册 | F-40 |
| U-40 | AppStorageTests | Preferences 改完后重启进程,值仍正确 | F-45 |

### UI 自动化

| ID | Case | 关联 |
| --- | --- | --- |
| UI-19 | 菜单栏 → Preferences → 窗口出现含 3 tab | F-39 |
| UI-20 | General → 切历史上限到 100 → 列表条数 ≤ 100 | F-40, F-43 |
| UI-21 | Shortcuts → 录新热键 → 录制完毕原 ⌘⇧V 失效,新热键生效 | F-41 |
| UI-22 | Appearance → 玻璃模糊度滑动 → 浮窗 backdrop blur 变化 | F-42 |
| UI-23 | Appearance → 卡片密度 = compact → 卡片宽高变小 | F-42 |
| UI-24 | 浮窗外点击空白 → 浮窗自动隐藏 | F-44 |

### 手工集成验证

- [ ] **M-23** Preferences General 开"开机启动" → 重启 Mac 验证 Stash 自动跑 [F-40]
- [ ] **M-24** 录全局热键到 ⌘⌥H → 关闭 Preferences → ⌘⌥H 唤起,⌘⇧V 不再唤起 [F-41]
- [ ] **M-25** 切系统暗/亮色 → Stash UI 跟随切 [F-42]
- [ ] **M-26** 历史上限 = 100,塞满后再复制新内容 → 最旧的被删,新的进来 [F-43]
- [ ] **M-27** 失焦自动隐藏关闭 → 点别处浮窗仍在 [F-44]
- [ ] **M-28** 跑 `./scripts/build-dmg.sh` → 产出 `Stash.dmg`,挂载后拖进 Applications 能正常启动 [F-47]
- [ ] **M-29** 在干净 Mac 账户(或新建测试账户)首次启动:权限引导走通,无崩溃 [F-13, F-46]

---

## 全局回归(每版都跑一次)

每个版本完成后,除了本版 checklist,还要跑这套通用回归:

- [ ] **M-R1** 内存:连续运行 24h,Activity Monitor 看 < 200MB(F-05 轮询不能漏 retain)
- [ ] **M-R2** CPU:无操作时 < 1%
- [ ] **M-R3** 1000 条历史下,横向滚动 ≥ 60fps
- [ ] **M-R4** 强杀(`kill -9`)后重启 → 历史完整,无损坏
- [ ] **M-R5** 与 Spotlight (⌘Space)、Raycast、Alfred 等其他常驻 app 不冲突
- [ ] **M-R6** Console.app 看启动到稳定运行无 crash log / no signpost error

---

## 测试基础设施待办

- [ ] 在 `StashTests/Helpers/` 加 `MockPasteboard.swift`(模拟 changeCount 自增)
- [ ] 在 `StashTests/Fixtures/` 放各类型测试样例(small.png, sample.rtf, code.sql, address.txt …)
- [ ] `StashUITests/Helpers/PasteBridge.swift` — 暴露给测试的"模拟复制 + 验证粘贴回调"通道
- [ ] CI(可选,自用项目可省):GitHub Actions `xcodebuild test` 工作流
