#!/usr/bin/env bash
# 用 mkisofs 重新生成无人值守应答盘 answer.iso
# 依赖：mkisofs / genisoimage（VMware Workstation 安装目录自带 mkisofs.exe 也能用）
# 用法：bash make-answer-iso.sh [autounatt.xml 路径] [输出 answer.iso 路径]
set -eu

XML="${1:-../vmx/autounatt.xml}"
OUT="${2:-../vmx/answer.iso}"
MKISOFS="${MKISOFS:-mkisofs}"

[ -f "$XML" ] || { echo "找不到应答文件：$XML"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Win7 只认根目录下名为 Autounattend.xml 的文件（大小写敏感场景都能命中）
cp "$XML" "$WORK/Autounattend.xml"

# -udf 让 Win7 的安装程序能正常读出长文件名；-J/-R 兼容其它读取器
"$MKISOFS" -o "$OUT" -udf -J -R -V "ANSWER" "$WORK/Autounattend.xml"

echo "已生成：$OUT"
ls -la "$OUT"
