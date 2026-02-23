import Cocoa
import Carbon.HIToolbox

class TextInserter {
    /// Delete n characters then paste replacement text via clipboard
    func replace(deleteCount n: Int, with text: String) {
        let src = CGEventSource(stateID: .combinedSessionState)
        for _ in 0..<n {
            let down = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_Delete), keyDown: true)
            down?.post(tap: .cgSessionEventTap)
            let up = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_Delete), keyDown: false)
            up?.post(tap: .cgSessionEventTap)
        }
        // Wait for deletes to be processed, then paste via clipboard (atomic, no event flood)
        usleep(100_000)
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        usleep(50_000)
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_ANSI_V), keyDown: true)
        vDown?.flags = .maskCommand
        vDown?.post(tap: .cgSessionEventTap)
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_ANSI_V), keyDown: false)
        vUp?.flags = .maskCommand
        vUp?.post(tap: .cgSessionEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let old = oldContents {
                pasteboard.clearContents()
                pasteboard.setString(old, forType: .string)
            }
        }
    }

    /// Type text directly via CGEvent Unicode (no clipboard, for streaming)
    func insertDelta(_ text: String) {
        let src = CGEventSource(stateID: .combinedSessionState)
        for char in text.utf16 {
            var c = char
            let down = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &c)
            down?.post(tap: .cgSessionEventTap)
            let up = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false)
            up?.post(tap: .cgSessionEventTap)
        }
    }

    func insert(_ text: String) {
        slog("上屏文字: \"\(text)\"")

        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to ensure pasteboard is ready
        usleep(50_000) // 50ms

        let src = CGEventSource(stateID: .combinedSessionState)
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_ANSI_V), keyDown: true)
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: UInt16(kVK_ANSI_V), keyDown: false)
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        vDown?.post(tap: .cgSessionEventTap)
        vUp?.post(tap: .cgSessionEventTap)
        slog("上屏 CGEvent 已发送")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let old = oldContents {
                pasteboard.clearContents()
                pasteboard.setString(old, forType: .string)
            }
        }
    }
}
