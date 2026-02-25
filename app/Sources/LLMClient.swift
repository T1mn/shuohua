import Foundation

struct LLMProvider {
    let endpoint: URL
    let model: String
    let apiKey: String
}

struct LLMClient {
    private static let timeout: TimeInterval = 15

    static func resolve() -> LLMProvider? {
        let defaults = UserDefaults.standard
        let provider = defaults.string(forKey: "provider") ?? "deepseek"

        switch provider {
        case "groq":
            guard let key = defaults.string(forKey: "groq_api_key"), !key.isEmpty else { return nil }
            let model = defaults.string(forKey: "groq_model") ?? "llama-3.3-70b-versatile"
            return LLMProvider(
                endpoint: URL(string: "https://api.groq.com/openai/v1/chat/completions")!,
                model: model,
                apiKey: key
            )
        case "custom":
            guard let key = defaults.string(forKey: "custom_api_key"), !key.isEmpty,
                  let ep = defaults.string(forKey: "custom_endpoint"), !ep.isEmpty,
                  let url = URL(string: ep),
                  let model = defaults.string(forKey: "custom_model"), !model.isEmpty
            else { return nil }
            return LLMProvider(endpoint: url, model: model, apiKey: key)
        default: // deepseek
            guard let key = defaults.string(forKey: "deepseek_api_key"), !key.isEmpty else { return nil }
            return LLMProvider(
                endpoint: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
                model: "deepseek-chat",
                apiKey: key
            )
        }
    }

    static func chatCompletion(provider: LLMProvider, systemPrompt: String, userMessage: String) -> String? {
        let body: [String: Any] = [
            "model": provider.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage],
            ],
            "temperature": 0.0,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }

        var request = URLRequest(url: provider.endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        let semaphore = DispatchSemaphore(value: 0)
        var result: String?

        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { semaphore.signal() }
            guard error == nil, let data else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else { return }
            result = content
        }.resume()

        semaphore.wait()
        return result
    }
}
