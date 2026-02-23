# Shuohua 说话

> Double-tap Ctrl. Speak. Text appears. Fully offline, one-click setup, hands-free typing.

[中文文档](README.zh-CN.md)

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
