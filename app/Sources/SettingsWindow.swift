import Cocoa
import SwiftUI

class SettingsWindow {
    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = NSHostingView(rootView: SettingsView())
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        w.title = "说话 — 设置"
        w.contentView = view
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }
}

private enum Provider: String, CaseIterable {
    case deepseek = "deepseek"
    case groq = "groq"
    case custom = "custom"

    var label: String {
        switch self {
        case .deepseek: "DeepSeek"
        case .groq: "Groq"
        case .custom: "自定义"
        }
    }
}

private struct SettingsView: View {
    @AppStorage("correction_enabled") private var correctionEnabled = true
    @AppStorage("provider") private var provider = "deepseek"

    // DeepSeek
    @AppStorage("deepseek_api_key") private var deepseekKey = ""

    // Groq
    @AppStorage("groq_api_key") private var groqKey = ""
    @AppStorage("groq_model") private var groqModel = "llama-3.3-70b-versatile"

    // Custom
    @AppStorage("custom_endpoint") private var customEndpoint = ""
    @AppStorage("custom_model") private var customModel = ""
    @AppStorage("custom_api_key") private var customKey = ""

    private var selectedProvider: Provider {
        Provider(rawValue: provider) ?? .deepseek
    }

    var body: some View {
        Form {
            Section {
                Toggle("启用文本修正", isOn: $correctionEnabled)
            }

            Section("API 提供商") {
                Picker("提供商", selection: $provider) {
                    ForEach(Provider.allCases, id: \.rawValue) { p in
                        Text(p.label).tag(p.rawValue)
                    }
                }

                switch selectedProvider {
                case .deepseek:
                    deepseekSection
                case .groq:
                    groqSection
                case .custom:
                    customSection
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Provider sections

    private var deepseekSection: some View {
        Group {
            SecureField("API Key", text: $deepseekKey, prompt: Text("sk-..."))
                .textFieldStyle(.roundedBorder)
            Text("模型: deepseek-chat")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var groqSection: some View {
        Group {
            SecureField("API Key", text: $groqKey, prompt: Text("gsk_..."))
                .textFieldStyle(.roundedBorder)
            Picker("模型", selection: $groqModel) {
                Text("Llama 3.3 70B").tag("llama-3.3-70b-versatile")
                Text("Qwen3 32B").tag("qwen/qwen3-32b")
                Text("Llama 3.1 8B").tag("llama-3.1-8b-instant")
            }
            Text("Groq 免费注册: console.groq.com")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var customSection: some View {
        Group {
            TextField("Endpoint", text: $customEndpoint, prompt: Text("https://api.example.com/v1/chat/completions"))
                .textFieldStyle(.roundedBorder)
            TextField("模型名称", text: $customModel, prompt: Text("model-name"))
                .textFieldStyle(.roundedBorder)
            SecureField("API Key", text: $customKey, prompt: Text("sk-..."))
                .textFieldStyle(.roundedBorder)
            Text("兼容 OpenAI chat completions 格式")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
