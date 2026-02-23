import Cocoa
import SwiftUI

private let logFile: FileHandle? = {
    let path = "/tmp/shuohua.log"
    FileManager.default.createFile(atPath: path, contents: nil)
    return FileHandle(forWritingAtPath: path)
}()

func slog(_ msg: String) {
    let line = "[shuohua] \(msg)\n"
    print(line, terminator: "")
    logFile?.seekToEndOfFile()
    logFile?.write(line.data(using: .utf8)!)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let hotkey = HotkeyManager()
    private let recorder = AudioRecorder()
    private let inserter = TextInserter()
    private let asr = ASREngine()
    private let cleaner = FillerCleaner()
    private let loading = LoadingWindow()
    private let hud = HUDWindow()
    private var isRecording = false
    private var isTuning = false
    private var modelLoaded = false
    private var memoryItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        slog("应用启动")
        setupMenuBar()
        checkAccessibility()
        loading.show()
        startASR()
        cleaner.start(
            progress: { [weak self] p, s in self?.loading.updateCleaner(p, s) },
            completion: { [weak self] in self?.loading.markCleanerDone(); self?.updateMemory() }
        )

        hotkey.onToggle = { [weak self] in self?.toggle() }
        hotkey.start()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "双击 Ctrl 开始/停止录音", action: nil, keyEquivalent: ""))
        memoryItem = NSMenuItem(title: "模型内存: 计算中...", action: nil, keyEquivalent: "")
        memoryItem.isEnabled = false
        menu.addItem(memoryItem)

        let modelMenu = NSMenu()
        for size in FillerCleaner.ModelSize.allCases {
            let item = NSMenuItem(title: size.label, action: #selector(switchModel(_:)), keyEquivalent: "")
            item.representedObject = size
            if size == cleaner.currentModel { item.state = .on }
            modelMenu.addItem(item)
        }
        let modelItem = NSMenuItem(title: "修正模型", action: nil, keyEquivalent: "")
        modelItem.submenu = modelMenu
        menu.addItem(modelItem)

        menu.addItem(NSMenuItem.separator())
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
                self?.updateMemory()
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
            let (text, ms) = self.asr.transcribe(samples: samples) { chunk in
                DispatchQueue.main.async {
                    self.inserter.insertDelta(chunk)
                }
            }
            slog("转录完成: \(text) (\(ms)ms)")

            DispatchQueue.main.async { self.isTuning = true; self.updateIcon(); self.hud.show("修正中...", duration: 0) }
            if let cleaned = self.cleaner.clean(text), cleaned != text, !cleaned.isEmpty {
                slog("文本修正: \(cleaned)")
                DispatchQueue.main.async {
                    self.inserter.replace(deleteCount: text.count, with: cleaned)
                }
            }
            DispatchQueue.main.async { self.isTuning = false; self.updateIcon(); self.hud.hide() }
        }
    }

    private func updateIcon() {
        if let btn = statusItem.button {
            let name = isRecording ? "mic.fill" : isTuning ? "sparkles" : "mic"
            btn.image = NSImage(systemSymbolName: name, accessibilityDescription: "Shuohua")
        }
    }

    private func updateMemory() {
        DispatchQueue.main.async {
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
            let kr = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
                }
            }
            if kr == KERN_SUCCESS {
                let mb = info.resident_size / (1024 * 1024)
                self.memoryItem.title = "模型内存: \(mb) MB"
            }
        }
    }

    @objc private func switchModel(_ sender: NSMenuItem) {
        guard let size = sender.representedObject as? FillerCleaner.ModelSize,
              size != cleaner.currentModel else { return }
        // Update checkmarks
        sender.menu?.items.forEach { $0.state = .off }
        sender.state = .on
        slog("切换修正模型: \(size.label)")
        hud.show("切换模型中...", duration: 0)
        cleaner.stop()
        cleaner.start(size: size, completion: { [weak self] in
            self?.updateMemory()
            self?.hud.hide()
        })
    }

    @objc private func openLog() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/tmp/shuohua.log"))
    }

    @objc private func openAccessibility() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func quit() {
        hotkey.stop()
        cleaner.stop()
        NSApp.terminate(nil)
    }
}
