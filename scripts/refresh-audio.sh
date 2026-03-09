#!/bin/bash
set -e

echo "==> 重启 macOS 音频服务 (coreaudiod)"
sudo killall coreaudiod
sleep 1
echo "✓ 音频服务已重启"
