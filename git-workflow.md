# Git 管理流程

## 一、分支命名规范

| 类型 | 命名格式 | 说明 |
| --- | --- | --- |
| 主干 | `master` | 稳定发布分支 |
| 需求分支 | `feat-vx.y.0` | 新版本需求开发(次版本号递增) |
| Bug 分支 | `feat-vx.y.z` | 修复分支(修订号递增) |

---

## 二、完整开发流程

### 1. 版本规划

- 确定本次版本号 `vx.y.z`
- 打开 `feat_list.md`,圈定该版本需求池中要开发的功能项,记录各项的 `feat_id`

### 2. 检出分支

从 `master` 拉取最新代码并检出新分支:

```bash
git checkout master
git pull origin master
git checkout -b feat-vx.y.0   # 需求版本
# 或
git checkout -b feat-vx.y.z   # bug 修复版本
```

### 3. 功能开发循环

对该版本需求池中的**每一个功能**,执行以下循环:

1. 从 `feat_list.md` 中取出一个 `feat_id` 对应的需求,开发功能
2. 跑该功能对应的测试用例
3. 测试通过后提交,commit message **必须带上 feat_id**:
   ```bash
   git add .
   git commit -m "feat(<feat_id>): <简要描述>"
   # 示例: git commit -m "feat(F-2026-001): 新增用户标签筛选"
   ```

4. 进入下一个功能,重复上述步骤

### 4. 版本回归测试

当前版本所有功能都开发完成后:

- 全量运行当前版本的所有测试用例
- 必须**全部通过**才能进入下一阶段

### 5. 预览测试

- 通知 Jimmy 进行预览测试
- 等待测试反馈
- 如有问题,回到第 3 步修复

### 6. 发布

收到 Jimmy「可发布」的确认后:

```bash
# 切回 master 并合入
git checkout master
git pull origin master
git merge --no-ff feat-vx.y.0

# 打 tag
git tag -a vx.y.0 -m "release vx.y.0"

# 推送
git push origin master
git push origin vx.y.0
```

---

## 三、流程总览

```
master
  │
  ├─► 检出 feat-vx.y.0 / feat-vx.y.z
  │      │
  │      ├─► 读 feat_list.md → 选定本版本需求池
  │      │
  │      ├─► 循环: 开发功能 → 跑对应测试 → commit (带 feat_id)
  │      │
  │      ├─► 全量跑当前版本测试用例
  │      │
  │      ├─► 通知 Jimmy 预览测试
  │      │
  │      └─► Jimmy 通知可发布
  │             │
  │             ▼
  └◄─── 合并回 master + 打 tag vx.y.0
```

---

## 四、关键约束(Checklist)

- [ ] 分支名严格遵循 `feat-vx.y.z` 格式
- [ ] 每个 commit message 都带 `feat_id`
- [ ] 每开发完一个功能必须跑对应测试,测试通过才提交
- [ ] 版本结束前必须全量回归测试
- [ ] 必须等 Jimmy 明确「可发布」才合入 master
- [ ] 合入后立即打 tag `vx.y.z`
