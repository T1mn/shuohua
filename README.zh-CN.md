# 说话 Shuohua

> 双击 Ctrl，说话，文字自动出现。完全离线，一键部署，解放你的双手。

[English](README.md)

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
bash scripts/rebuild-open.sh
```

首次启动会自动下载模型（约 1GB），之后秒启。需授予麦克风和辅助功能权限。

## 重新编译 / 安装 / 打开

```bash
bash scripts/rebuild-open.sh
```

这个脚本会自动：
- 先退出当前正在运行的 App（如果有）
- 重新编译并签名 `build/说话.app`
- 安装到 `/Applications/说话.app`
- 打开安装后的 App

如果你在系统设置里看到权限已打开，但实际仍不生效，可执行：

```bash
bash scripts/rebuild-open.sh --reset-tcc
```

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

## 许可证

MIT
