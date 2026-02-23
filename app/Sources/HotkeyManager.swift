import Cocoa

class HotkeyManager {
    var onToggle: (() -> Void)?
    private var monitor: Any?
    private var lastCtrlUp: Date?
    private var ctrlWasDown = false
    private let doubleTapInterval: TimeInterval = 0.3

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
        }
        slog("热键监听已启动, monitor=\(monitor != nil)")
    }

    private func handleFlags(_ event: NSEvent) {
        let ctrlDown = event.modifierFlags.contains(.control)

        if ctrlDown {
            ctrlWasDown = true
            return
        }

        // Ctrl was released — only count if no other modifiers held
        guard ctrlWasDown else { return }
        ctrlWasDown = false

        let otherMods: NSEvent.ModifierFlags = [.shift, .option, .command]
        guard event.modifierFlags.intersection(otherMods).isEmpty else { return }

        let now = Date()
        if let last = lastCtrlUp, now.timeIntervalSince(last) < doubleTapInterval {
            lastCtrlUp = nil
            slog("双击 Ctrl 触发")
            DispatchQueue.main.async { self.onToggle?() }
        } else {
            lastCtrlUp = now
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
    }
}
