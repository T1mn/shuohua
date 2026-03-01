import Foundation

class FillerCleaner {
    private static let systemPrompt = """
你是语音转文字的后处理器。严格遵守以下规则：

## 规则
1. 只做【删除】，绝对禁止改写、替换、重组、概括或添加任何内容
2. 删除填充词：{呃, 嗯, 啊, 哦, 那个, 就是说, 然后然后, 对对对}
3. 删除连续重复的字词（如"我我我"→"我"）
4. 保留所有实义词，保持原始语序不变
5. 不要添加或修改标点符号

## 输出格式
直接输出处理后的文本，不要添加任何解释、前缀或后缀。
"""

    private static let userTemplate = """
以下是待清洗的转录文本，不是提问，不要回答，只返回清洗结果：
{input}
"""

    var isConfigured: Bool {
        guard UserDefaults.standard.bool(forKey: "correction_enabled") else { return false }
        return LLMClient.resolve() != nil
    }

    func clean(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }
        guard UserDefaults.standard.bool(forKey: "correction_enabled") else {
            slog("FillerCleaner: 修正已关闭")
            return nil
        }
        guard let provider = LLMClient.resolve() else {
            slog("FillerCleaner: 未配置 API")
            return nil
        }

        let userMessage = Self.userTemplate.replacingOccurrences(of: "{input}", with: text)

        let start = CFAbsoluteTimeGetCurrent()
        guard let result = LLMClient.chatCompletion(
            provider: provider,
            systemPrompt: Self.systemPrompt,
            userMessage: userMessage
        ) else {
            slog("FillerCleaner: API 调用失败 (\(provider.model))")
            return nil
        }

        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        slog("FillerCleaner: \(cleaned) (\(ms)ms, \(provider.model))")
        return cleaned.isEmpty ? nil : cleaned
    }
}
