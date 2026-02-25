import Cocoa

class LoadingWindow {
    private var window: NSWindow?
    private var asrBar: NSProgressIndicator!
    private var asrLabel: NSTextField!

    func show() {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 90),
            styleMask: [.titled],
            backing: .buffered, defer: false
        )
        w.title = "说话 — 加载模型"
        w.center()
        w.isReleasedWhenClosed = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        asrLabel = makeLabel("语音识别模型...")
        asrBar = makeBar()

        stack.addArrangedSubview(asrLabel)
        stack.addArrangedSubview(asrBar)

        w.contentView?.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: w.contentView!.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: w.contentView!.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: w.contentView!.centerYAnchor),
            asrBar.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])

        w.orderFrontRegardless()
        self.window = w
    }

    func updateASR(_ progress: Double, _ status: String) {
        DispatchQueue.main.async {
            self.asrBar.doubleValue = progress * 100
            self.asrLabel.stringValue = "语音识别: \(status)"
        }
    }

    func markASRDone() {
        DispatchQueue.main.async { self.window?.close() }
    }

    private func makeLabel(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = .systemFont(ofSize: 12)
        return l
    }

    private func makeBar() -> NSProgressIndicator {
        let b = NSProgressIndicator()
        b.style = .bar
        b.minValue = 0
        b.maxValue = 100
        b.isIndeterminate = false
        return b
    }
}
