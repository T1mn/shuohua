import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let hotkey = HotkeyManager()
    private let recorder = AudioRecorder()
    private let inserter = TextInserter()
    private let asr = ASREngine()
    private let cleaner = FillerCleaner()
    private let loading = LoadingWindow()
    private let hud = HUDWindow()
    private let settings = SettingsWindow()
    private var isRecording = false
    private var modelLoaded = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "correction_enabled": true,
            "provider": "deepseek",
            "groq_model": "llama-3.3-70b-versatile",
        ])
        slog("应用启动")
        setupMenuBar()
        checkAccessibility()
        loading.show()
        startASR()

        hotkey.onToggle = { [weak self] in self?.toggle() }
        hotkey.start()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "双击 Ctrl 开始/停止录音", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "查看运行日志", action: #selector(openLog), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "开启辅助功能权限...", action: #selector(openAccessibility), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出说话", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func checkAccessibility() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        slog("辅助功能权限: \(trusted ? "已授权" : "未授权")")
    }

    private func startASR() {
        asr.loadModel(progress: { [weak self] p, s in
            self?.loading.updateASR(p, s)
        }) { [weak self] result in
            switch result {
            case .success(let ms):
                self?.modelLoaded = true
                self?.loading.markASRDone()
                slog("模型加载完成 (\(ms)ms)")
            case .failure(let e):
                self?.loading.markASRDone()
                slog("模型加载失败: \(e)")
            }
        }
    }

    private func toggle() {
        slog("toggle: isRecording=\(isRecording)")
        if isRecording {
            stopAndTranscribe()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard modelLoaded else {
            slog("模型尚未加载完成")
            return
        }
        do {
            try recorder.start()
            isRecording = true
            updateIcon()
        } catch {
            slog("录音失败: \(error)")
        }
    }

    private func stopAndTranscribe() {
        let samples = recorder.stop()
        isRecording = false
        updateIcon()

        guard !samples.isEmpty else {
            slog("录音为空，跳过转录")
            return
        }

        slog("开始转录...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var streamed = ""
            let (text, ms) = self.asr.transcribe(samples: samples) { chunk in
                streamed += chunk
                DispatchQueue.main.async {
                    self.inserter.insertDelta(chunk)
                }
            }
            slog("转录完成: \(text) (\(ms)ms)")
            slog("诊断: streamed=\(streamed.count) final=\(text.count) utf16=\(text.utf16.count) match=\(streamed == text)")
            if streamed != text {
                slog("诊断-streamed: \(streamed)")
                slog("诊断-final:    \(text)")
            }

            let deleteCount = streamed.count
            if self.cleaner.isConfigured {
                DispatchQueue.main.async { self.hud.show("修正中...", duration: 0) }
                if let cleaned = self.cleaner.clean(text), cleaned != text, !cleaned.isEmpty {
                    slog("文本修正: \(cleaned) (deleteCount=\(deleteCount))")
                    DispatchQueue.main.async {
                        self.inserter.replace(deleteCount: deleteCount, with: cleaned)
                    }
                }
                DispatchQueue.main.async { self.hud.hide() }
            } else {
                slog("跳过文本修正: 未设置 API Key")
            }
        }
    }

    private func updateIcon() {
        if let btn = statusItem.button {
            let name = isRecording ? "mic.fill" : "mic"
            btn.image = NSImage(systemSymbolName: name, accessibilityDescription: "Shuohua")
        }
    }

    @objc private func showSettings() {
        settings.show()
    }

    @objc private func openLog() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/tmp/shuohua.log"))
    }

    @objc private func openAccessibility() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func quit() {
        hotkey.stop()
        NSApp.terminate(nil)
    }
}
