# Contributing to shuohua

Thanks for your interest in contributing to shuohua — a macOS menu bar voice-to-text app built with Swift and Qwen3-ASR, with DeepSeek API for text refinement.

## Prerequisites

- macOS 14 (Sonoma) or later
- Apple Silicon (M1 or later)
- Xcode 15+ or Swift 5.9+
- ~1 GB free disk space for the ASR model cache

## Getting Started

```bash
git clone https://github.com/T1mn/shuohua.git
cd shuohua
bash scripts/build.sh
open build/说话.app
```

On first launch, grant the app **Microphone** and **Accessibility** permissions when prompted.

## Project Structure

```
app/Sources/       Swift source files (the entire app)
app/Package.swift  Swift package manifest and dependencies
scripts/           Build, packaging, and icon scripts
.github/workflows/ CI release workflow
build/             Build output (generated)
dist/              Distribution artifacts (generated)
```

## Key Source Files

All source files live in `app/Sources/`.

| File | Purpose |
|------|---------|
| `AppDelegate.swift` | App lifecycle, logging setup, menu bar initialization |
| `ShuohuaApp.swift` | SwiftUI app entry point |
| `ASREngine.swift` | MLX-based speech recognition using Qwen3-ASR |
| `AudioRecorder.swift` | Microphone capture and audio buffer management |
| `FillerCleaner.swift` | Strips filler words via DeepSeek API |
| `DeepSeekClient.swift` | HTTP client for DeepSeek chat completions API |
| `TextInserter.swift` | Inserts transcribed text at the cursor via Accessibility API |
| `HUDWindow.swift` | Floating overlay showing transcription status |
| `HotkeyManager.swift` | Global hotkey registration and handling |
| `StatusView.swift` | Menu bar status item UI |
| `LoadingWindow.swift` | ASR model loading progress indicator |

## Making Changes

1. Fork the repo and create a branch: `git checkout -b my-change`
2. Make your changes in `app/Sources/`
3. Build and test locally:
   ```bash
   bash scripts/build.sh
   open build/说话.app
   ```
4. Verify your change works (record audio, check transcription output)
5. Submit a pull request against `main`

## Code Style

- Follow the existing Swift conventions in the codebase
- No SwiftLint or formatter is configured — just keep it consistent
- Prefer minimal, readable code over clever abstractions

## Reporting Issues

Open an issue on [GitHub Issues](https://github.com/T1mn/shuohua/issues) and include:

- macOS version (e.g. 15.3)
- Chip type (e.g. M1, M2 Pro, M4)
- What you expected vs. what happened
- Relevant logs from `/tmp/shuohua.log`
