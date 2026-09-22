# ============================================================
# 新成员环境初始化（Windows / PowerShell）
#
# 在项目根目录执行（WorkBuddy 或 PowerShell 均可）：
#     powershell -ExecutionPolicy Bypass -File tools\setup.ps1
#
# 做完这几件事：
#   1. 检查 git 与 git-lfs 是否装好
#   2. 为本仓库启用 LFS
#   3. 启用 .githooks 里的提交前检查
#   4. 挂上提交信息模板
#   5. 关掉 core.autocrlf（换行符交给 .gitattributes 统一管理）
#   6. 真正拉取 LFS 大文件
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Ok($msg)   { Write-Host "  [OK]   $msg" }
function Write-Fail($msg) { Write-Host "  [FAIL] $msg" }

Write-Host ""
Write-Host "==== 1. 检查工具链 ===="

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = (git --version)
    Write-Ok "git 已安装：$gitVersion"
} else {
    Write-Fail "没有找到 git，请先安装 https://git-scm.com/downloads"
    exit 1
}

if (Get-Command git-lfs -ErrorAction SilentlyContinue) {
    $lfsVersion = (git lfs version)
    Write-Ok "git-lfs 已安装：$lfsVersion"
} else {
    Write-Fail "没有找到 git-lfs，请先安装 https://git-lfs.com"
    Write-Host "       没装 LFS 的话，美术/音频资源拿到的只会是一段指针文本。"
    exit 1
}

if (-not (Test-Path ".git")) {
    Write-Fail "当前目录不是 Git 仓库根目录，请先 cd 到项目根目录再执行"
    exit 1
}

Write-Host ""
Write-Host "==== 2. 为当前仓库启用 Git LFS ===="
git lfs install --local
Write-Ok "已为当前仓库启用 LFS"

Write-Host ""
Write-Host "==== 3. 启用提交前检查钩子 ===="
git config core.hooksPath .githooks
Write-Ok "已指向 .githooks"

Write-Host ""
Write-Host "==== 4. 挂上提交信息模板 ===="
git config commit.template .gitmessage
Write-Ok "提交时自动带出模板"

Write-Host ""
Write-Host "==== 5. 统一换行符处理方式 ===="
git config core.autocrlf false
Write-Ok "core.autocrlf = false（换行符由 .gitattributes 统一控制）"

Write-Host ""
Write-Host "==== 6. 拉取 LFS 大文件 ===="
git lfs pull
Write-Ok "LFS 资源已就绪"

Write-Host ""
Write-Host "全部完成。现在可以直接用 Godot 打开这个目录了。"
Write-Host "日常流程与红线规则见 README.md 与 CONTRIBUTING.md"
Write-Host ""
