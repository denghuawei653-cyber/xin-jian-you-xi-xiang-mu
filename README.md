# 新建游戏项目

基于 **Godot 4.7** 的团队协作仓库。

> 本文档是新成员的上手入口。协作细则、红线规则见 [CONTRIBUTING.md](CONTRIBUTING.md)，
> 场景冲突怎么救见 [docs/scene-conflict-playbook.md](docs/scene-conflict-playbook.md)。

---

## 1. 环境要求

| 工具 | 版本要求 | 说明 |
| --- | --- | --- |
| Godot | **4.7**（务必与 `project.godot` 一致） | 大版本必须全员统一，否则场景文件会被反复改写 |
| Git | 2.30 以上 | |
| Git LFS | 必须安装 | 美术 / 音频 / 模型资源都走 LFS，不装只能拿到指针文件 |

一次装齐：

- Windows：`winget install Git.Git` + 到 https://git-lfs.com 下载安装
- macOS：`brew install git git-lfs`
- Ubuntu：`sudo apt install git git-lfs`

---

## 2. 新成员：克隆并初始化（约 3 分钟）

```bash
git clone <仓库地址>
cd <项目目录>

# 初始化：启用 LFS、装提交钩子、挂提交模板、拉大文件
git lfs install            # 每台机器只需执行一次
sh tools/setup.sh          # macOS / Linux / Git Bash
```

Windows 上也可以用 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File tools\setup.ps1
```

做完之后直接用 Godot 打开这个目录即可。**不要**手动把项目目录复制来复制去，
也不要从别人那里拷 `.godot/` 文件夹。

---

## 3. 日常开发流程

```
1. 拉最新代码            git switch main && git pull
2. 开功能分支            git switch -c feat/jump-system
3. 开发 + 随手提交        git commit -m "feat(player): 加入二段跳"
4. 同步主干              git fetch origin && git rebase origin/main
5. 推上去开 PR           git push -u origin feat/jump-system
6. 通过 CI + 审核后合并   由审核者在 GitHub 上点 Merge
7. 删掉本地分支           git switch main && git pull && git branch -d feat/jump-system
```

**分支命名**（`类型/简短说明`，全小写、用连字符）：

| 前缀 | 用途 | 示例 |
| --- | --- | --- |
| `feat/` | 新功能 | `feat/inventory-ui` |
| `fix/` | 修 Bug | `fix/save-corrupt-on-quit` |
| `refactor/` | 重构 | `refactor/state-machine` |
| `art/` | 纯美术资源 | `art/hero-rework` |
| `chore/` | 构建、CI、杂项 | `chore/bump-godot-4.7.1` |

`main` 是随时可发布的稳定分支，`develop` 是日常集成分支，两者都**不直接提交**。
提交钩子会在你往这两个分支提交时给出提醒。

---

## 4. 提交信息规范

格式：`<类型>(<影响范围>): <一句话说明>`

```
feat(player): 加入二段跳与落地缓冲
fix(ui): 修复背包数量在 99 时溢出显示
art(hero): 重画主角待机帧
build(export): 补上 Android 导出的 arm64 架构
```

合法的类型：`feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert`

写错会被 `commit-msg` 钩子拦下。提交时编辑器里会自动带出模板，照着填即可。
正文请写「**为什么**这么改」，而不是复述代码改了什么。

---

## 5. 关于 Git LFS（重点，新人最容易踩坑）

仓库里这些扩展名由 LFS 托管：图片（png/jpg/psd/xcf…）、音频（wav/ogg/mp3…）、
3D 源文件（blend/fbx/glb…）、字体、视频。

- 克隆后如果发现图片打不开、音频是几行文字，说明 **LFS 没生效**，执行：
  ```bash
  git lfs install --local && git lfs pull
  ```
- 新增了大体积资源后，确认它确实进了 LFS：
  ```bash
  git lfs ls-files           # 列出仓库里所有 LFS 文件
  git lfs status             # 查看当前待提交文件的 LFS 状态
  ```
- `psd` / `blend` / `fbx` 这类**根本无法合并**的源文件已开启锁定：

  ```bash
  git lfs lock assets/hero.psd        # 开工前上锁
  git lfs unlock assets/hero.psd      # 改完解锁
  git lfs locks                       # 看看谁锁了什么
  ```

  这样能避免两个人同时改同一份 PSD，最后只能二选一。

---

## 6. 提交前的自动检查

钩子会在 `git commit` 时自动拦截这几类问题：

- 把 `.godot/` 编辑器缓存提交进来
- 超过 20 MB 的文件绕过 LFS 直接入库
- `export_presets.cfg` 等配置里疑似混入了密钥
- 提交信息不符合规范（类型写错、格式不对）
- 直接往 `main` / `develop` 上提交（仅提醒）

确需临时跳过用 `git commit --no-verify`，但**不要**把它当成习惯。

---

## 7. CI 会检查什么

推上 GitHub 后自动跑三个任务：

| 任务 | 作用 |
| --- | --- |
| 仓库卫生检查 | `.godot/` 是否混入、大文件是否都走了 LFS、有无明文密钥 |
| GDScript 规范检查 | 用 `gdlint` 检查代码风格 |
| Godot 项目导入检查 | 用无头 Godot 真实打开项目，检查资源导入和脚本解析是否报错 |

CI 必须全绿才能合并。本地想提前自查，跑：

```bash
sh tools/ci/repo-hygiene.sh
```

---

## 8. 目录结构约定

```
├─ project.godot           项目配置（要提交）
├─ export_presets.cfg      导出预设（要提交，但别把密钥写进去）
├─ scenes/                 场景与关卡
├─ scripts/                游戏逻辑脚本
├─ assets/                 美术、音频、字体等资源
├─ addons/                 第三方插件
├─ tests/                  测试
├─ docs/                   设计文档与协作文档
├─ tools/                  工程脚本（环境初始化、CI 辅助）
├─ .github/                PR / Issue 模板与 CI 配置
├─ .githooks/              提交前的自动检查
├─ .gitignore              哪些东西不入库
├─ .gitattributes          换行符规则 + LFS 托管规则
└─ .editorconfig           编辑器缩进与编码统一
```

---

## 9. 常见问题

**Q：`git clone` 后 Godot 打开报一堆资源缺失？**
LFS 没拉全，执行 `git lfs pull`。

**Q：场景文件冲突了，怎么解？**
别手改 `.tscn`。见 [docs/scene-conflict-playbook.md](docs/scene-conflict-playbook.md)。

**Q：我不小心提交了 `.godot/`，怎么撤回？**
```bash
git rm -r --cached .godot
git commit -m "chore: 移除误提交的 Godot 缓存"
```

**Q：为什么我的 diff 显示整个文件都改了，其实只改了一行？**
换行符问题。确认 `git config core.autocrlf` 是 `false`，并重新执行一次 `sh tools/setup.sh`。

**Q：Godot 版本不一致会怎样？**
旧版本打开新版本保存的场景会丢数据。全员必须锁同一个 4.7.x，升级时统一行动，
并在 `chore/` 分支里一起升，同时更新 `.github/workflows/ci.yml` 里的 `GODOT_VERSION`。

---

## 10. 当前已配置 / 仍需人工处理

### 已在远端配好

| 项目 | 状态 |
|---|---|
| 远端仓库 | `https://github.com/denghuawei653-cyber/xin-jian-you-xi-xiang-mu`（公开） |
| 分支 | `main`（默认）+ `develop` |
| CODEOWNERS | 已填 `@denghuawei653-cyber` 并启用 |
| CI | 已在两个分支上跑通：仓库卫生检查 / GDScript 规范检查 / Godot 项目导入检查 |
| 合并策略 | 已禁用 merge commit（只允许 squash / rebase）→ 保证线性历史 |
| 合并后自动删分支 | 已开启 |
| 推送凭据 | `gh auth setup-git` 已配好（HTTPS + gh token） |

### ✅ 分支保护已启用（2026-09-22 仓库转公开后）

`main` 已开启硬保护，以下规则由 GitHub 强制执行，绕不过去：

| 规则 | 含义 |
|---|---|
| Require pull request | 不能直接 push 到 `main`，必须走 PR |
| 1 个 approve | 至少一人审核通过才能合并 |
| Require review from Code Owners | 涉及 `.github/`、`docs/` 等归属目录的改动必须负责人审 |
| Require status checks（3 项 CI 全绿 + 分支最新） | CI 红灯或落后于 `main` 一律禁止合并 |
| Require linear history | 禁止 merge commit |
| 禁止 force push / 删除分支 | 历史不可改写 |

> 管理员（仓库 owner）默认不受 `enforce_admins` 约束 —— 即你自己仍可绕过 PR 直推。
> 想连自己也锁死的话，到 Settings → Branches → Branch protection 里勾上
> **Do not allow bypassing the above settings**。

### 仍需人工处理

- [ ] 视需要补充 `LICENSE`
- [ ] 第一个 PR 合进来后，确认 CI 三个检查都出现在 PR 的 checks 里
