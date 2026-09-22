# ============================================================
# 仓库卫生检查（可在本地手动跑，也会在 CI 上跑）
#
#     sh tools/ci/repo-hygiene.sh
#
# 四件事：
#   1. .godot/ 等本机缓存没有被提交
#   2. 超过 1 MB 的文件都必须是 Git LFS 指针
#   3. 导出配置里没有明文密钥
#   4. 自动生成的中间产物没有被提交
# ============================================================

set -u

status=0
LIST=$(mktemp)

problem() {
	printf '\n[FAIL] %s\n' "$1"
	status=1
}

note() {
	printf '[ OK ] %s\n' "$1"
}

# ------------------------------------------------------------
printf '\n==== 1. 检查本机缓存是否被提交 ====\n'
bad_cache=$(git ls-files -- .godot)
if [ -n "$bad_cache" ]; then
	problem ".godot/ 被提交进了版本库，请执行： git rm -r --cached .godot"
	printf '%s\n' "$bad_cache" | head -n 20
else
	note ".godot/ 未被提交"
fi

bad_import=$(git ls-files -- '.import')
if [ -n "$bad_import" ]; then
	problem ".import/ 被提交进了版本库（Godot 3 遗留缓存），请执行： git rm -r --cached .import"
else
	note ".import/ 未被提交"
fi

# ------------------------------------------------------------
printf '\n==== 2. 检查大文件是否都走了 LFS ====\n'
LIMIT=1048576   # 1 MB

git ls-files > "$LIST"
bad_big=0
while IFS= read -r f; do
	[ -f "$f" ] || continue
	size=$(wc -c < "$f" | tr -d ' ')
	[ "$size" -gt "$LIMIT" ] || continue

	# LFS 文件在未拉取的实际内容时是个 ~130 字节的指针文件
	firstline=$(sed -n '1p' "$f" 2>/dev/null || printf '')
	case "$firstline" in
		version\ https://git-lfs.github.com/spec/*)
			continue   # 是指针，正常
			;;
	esac

	bad_big=1
	problem "文件超过 1 MB 却没走 LFS： $f（约 $((size / 1024)) KB）"
done < "$LIST"

if [ "$bad_big" -eq 0 ]; then
	note "所有超过 1 MB 的文件都是 LFS 指针"
fi

# ------------------------------------------------------------
printf '\n==== 3. 检查导出配置里是否有明文密钥 ====\n'
found_secret=0
for f in export_presets.cfg export.cfg; do
	[ -f "$f" ] || continue
	if grep -nE 'keystore/(debug|release)_password[[:space:]]*=[[:space:]]*"..*"|"api_key"[[:space:]]*:[[:space:]]*"..*"|"secret"[[:space:]]*:[[:space:]]*"..*"' "$f" >/dev/null 2>&1; then
		found_secret=1
		problem "$f 里疑似存在明文密钥 / 口令，请改成从环境变量读取"
	fi
done

if [ "$found_secret" -eq 0 ]; then
	note "未在导出配置中发现明文密钥"
fi

# ------------------------------------------------------------
printf '\n==== 4. 检查自动生成的中间产物 ====\n'
bad_gen=$(git ls-files -- '*.translation')
if [ -n "$bad_gen" ]; then
	problem "*.translation 是由 CSV 自动生成的，不该入库："
	printf '%s\n' "$bad_gen"
else
	note "没有把自动生成的翻译资源提交进来"
fi

# ------------------------------------------------------------
rm -f "$LIST"

if [ "$status" -eq 0 ]; then
	printf '\n全部检查通过\n\n'
else
	printf '\n检查未通过，请按上面的提示修正\n\n'
fi

exit "$status"
