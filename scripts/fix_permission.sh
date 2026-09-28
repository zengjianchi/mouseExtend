#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
APP_PATH="$DIR/MouseExtend.app"

echo "=========================================="
echo "  MouseExtend 辅助功能权限一键修复/重置工具"
echo "=========================================="

echo "[1/3] 重置可能过期的旧签名缓存..."
tccutil reset Accessibility com.antigravity.MouseExtend 2>/dev/null || true

echo "[2/3] 打开系统设置 -> 辅助功能面板..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo "[3/3] 在访达 (Finder) 中高亮定位 MouseExtend.app..."
open -R "$APP_PATH"

echo "------------------------------------------"
echo "💡 操作说明："
echo "1. 系统设置窗口已打开，并在访达中为您高亮选中了【MouseExtend.app】；"
echo "2. 如果系统列表中有旧的 MouseExtend，请选中并点击【-】减号删除；"
echo "3. 直接把访达中高亮的【MouseExtend.app】拖拽进系统设置的辅助功能列表中，并开启开关；"
echo "4. 开启后重新运行: ./scripts/run.sh 即可！"
echo "=========================================="
