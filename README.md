# 说话 Shuohua

> 双击 Ctrl，说话，文字自动出现。完全离线，一键部署，解放你的双手。

macOS 菜单栏语音输入工具，基于 Apple Silicon 本地推理，无需联网，无需 API Key。模型首次运行自动下载，开箱即用。

## 特性

- 🎤 双击 Ctrl 随时唤起，任意窗口可用
- 🧠 Qwen3-ASR 语音识别 + Qwen3 文本修正，自动去除口误和重复
- 🔒 完全离线运行，录音不出本机
- 💡 浮动 HUD 提示，全屏应用中也能看到状态
- ⚙️ 可切换修正模型（轻量 0.6B / 推荐 1.7B）

## 快速开始

```bash
git clone https://github.com/T1mn/shuohua.git
cd shuohua
bash scripts/build.sh
open build/说话.app
```

首次启动会自动下载模型（约 1GB），之后秒启。需授予麦克风和辅助功能权限。

## 使用

| 操作 | 说明 |
|------|------|
| 双击 Ctrl | 开始/停止录音 |
| 菜单栏图标 | 查看状态、切换模型、查看日志 |

## 架构

```
Swift 菜单栏 App (MLX)
├── HotkeyManager     双击 Ctrl 热键
├── AudioRecorder      AVAudioEngine 录音
├── ASREngine          Qwen3-ASR-0.6B-4bit 语音识别（流式输出）
├── FillerCleaner      Qwen3-1.7B-4bit 文本修正
├── TextInserter       CGEvent 模拟键入 / 剪贴板粘贴
└── HUDWindow          浮动状态提示
```

## 系统要求

- macOS 14+ / Apple Silicon (M1 及以上)
- 约 1GB 磁盘空间（模型缓存）
- 约 600MB 内存

---

# Shuohua

> Double-tap Ctrl. Speak. Text appears. Fully offline, one-click setup, hands-free typing.

A macOS menu bar voice-to-text tool powered by on-device inference on Apple Silicon. No internet, no API keys. Models download automatically on first launch.

## Features

- 🎤 Double-tap Ctrl to dictate anywhere, in any app
- 🧠 Qwen3-ASR speech recognition + Qwen3 text refinement (removes stutters and filler words)
- 🔒 Fully offline — audio never leaves your machine
- 💡 Floating HUD visible even in full-screen apps
- ⚙️ Switchable refinement model (lightweight 0.6B / recommended 1.7B)

## Quick Start

```bash
git clone https://github.com/T1mn/shuohua.git
cd shuohua
bash scripts/build.sh
open build/说话.app
```

Models (~1GB) download automatically on first launch. Grant microphone and accessibility permissions when prompted.

## Usage

| Action | Description |
|--------|-------------|
| Double-tap Ctrl | Start / stop recording |
| Menu bar icon | View status, switch model, open logs |

## Architecture

```
Swift menu bar app (MLX)
├── HotkeyManager     Double-Ctrl hotkey
├── AudioRecorder      AVAudioEngine capture
├── ASREngine          Qwen3-ASR-0.6B-4bit speech recognition (streaming)
├── FillerCleaner      Qwen3-1.7B-4bit text refinement
├── TextInserter       CGEvent keystrokes / clipboard paste
└── HUDWindow          Floating status overlay
```

## Requirements

- macOS 14+ / Apple Silicon (M1 or later)
- ~1GB disk space (model cache)
- ~600MB RAM

## License

MIT
