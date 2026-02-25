# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Replace local Qwen3 text refinement with DeepSeek API (`deepseek-chat`)
- Simplify loading window to only show ASR model progress
- Remove model switching menu (no longer needed with API-based refinement)

### Added

- DeepSeek API key configuration dialog in menu bar
- Unit tests for text encoding, API response parsing, and prompt construction

## [0.1.0] - 2025-01-01

### Added

- Double-tap Ctrl hotkey to start/stop voice recording
- Qwen3-ASR-0.6B on-device speech recognition with streaming output
- Text refinement to remove filler words and stutters
- Floating HUD overlay visible in full-screen apps
- Menu bar status icon with recording state indicator
- macOS accessibility permission integration
- DMG packaging for distribution

[Unreleased]: https://github.com/T1mn/shuohua/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/T1mn/shuohua/releases/tag/v0.1.0
