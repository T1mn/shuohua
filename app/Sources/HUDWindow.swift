import Cocoa

class HUDWindow {
    private var window: NSPanel?
    private var label: NSTextField?
    private var hideTimer: Timer?

    func show(_ text: String, duration: TimeInterval = 2.0) {
        DispatchQueue.main.async { self._show(text, duration: duration) }
    }

    func hide() {
        DispatchQueue.main.async { self._hide() }
    }

    private func _show(_ text: String, duration: TimeInterval) {
        hideTimer?.invalidate()

        if let label { label.stringValue = text }
        else { createWindow(text) }

        window?.alphaValue = 0
        window?.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            window?.animator().alphaValue = 1
        }

        if duration > 0 {
            hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?._hide()
            }
        }
    }

    private func _hide() {
        hideTimer?.invalidate()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            window?.animator().alphaValue = 0
        }) { self.window?.orderOut(nil) }
    }

    private func createWindow(_ text: String) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 32),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered, defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        let l = NSTextField(labelWithString: text)
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .white
        l.alignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false

        panel.contentView?.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: panel.contentView!.centerXAnchor),
            l.centerYAnchor.constraint(equalTo: panel.contentView!.centerYAnchor),
        ])

        if let screen = NSScreen.main {
            let x = screen.frame.maxX - 120 - 8
            let y = screen.frame.maxY - screen.visibleFrame.origin.y - 32 - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = panel
        self.label = l
    }
}
