# 说话 Shuohua

macOS 本地语音转文字工具。按下 Fn 双击，说话，文字自动出现在光标位置。

## 特性

- 完全离线，隐私安全
- 支持多个 ASR 模型（SenseVoice、Paraformer、Whisper）
- 任意窗口均可使用
- 内置 benchmark 工具对比模型性能

## 快速开始

### 1. 下载模型

```bash
make download-model MODEL=sensevoice-small
```

### 2. 构建

```bash
make build
```

### 3. 运行

打开 `build/Shuohua.app`，双击 Fn 键开始/停止录音。

需要授予麦克风和辅助功能权限（系统设置 > 隐私与安全性）。

## 支持的模型

| 模型 | 语言 | 大小 | 速度 |
|------|------|------|------|
| SenseVoice Small | 中/英/日/韩/粤 | 234MB | 极快 |
| Paraformer Large | 中文(+英) | 232MB | 很快 |
| Whisper Large v3 | 99+语言 | 1.5GB | 慢 |

## Benchmark

```bash
make download-model MODEL=sensevoice-small
make download-model MODEL=paraformer-zh
make bench ARGS="--models sensevoice-small,paraformer-zh --dataset test-audio/dataset.json"
```

## 架构

```
Swift 菜单栏 App ──stdin/stdout JSON-RPC──> Node.js Worker (sherpa-onnx-node)
  ├── HotkeyManager (Fn 双击)                  ├── recognizer.ts
  ├── AudioRecorder (AVAudioEngine)             ├── models.ts
  ├── TextInserter (剪贴板+Cmd+V)               └── protocol.ts
  └── WorkerBridge (JSON-RPC)
```

## 开发

```bash
# 构建 worker
cd worker && npm install && npm run build

# 构建 Swift app
cd app && swift build

# 下载模型后运行
cd app && swift run
```

## License

MIT
