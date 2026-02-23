import Foundation
import MLX
import Qwen3ASR
import Qwen3Common

class FillerCleaner {
    enum ModelSize: String, CaseIterable {
        case small = "mlx-community/Qwen3-0.6B-4bit"
        case medium = "mlx-community/Qwen3-1.7B-4bit"

        var label: String {
            switch self {
            case .small: return "Qwen3-0.6B (轻量)"
            case .medium: return "Qwen3-1.7B (推荐)"
            }
        }

        var config: TextDecoderConfig {
            switch self {
            case .small: return .small
            case .medium:
                var c = TextDecoderConfig.large
                c.bits = 4
                return c
            }
        }
    }

    private var model: QuantizedTextModel?
    private var tokenizer: Qwen3Tokenizer?
    private(set) var currentModel: ModelSize = .medium

    // Token IDs (same vocab as ASR model)
    private static let imStartId: Int32 = 151644
    private static let imEndId: Int32 = 151645
    private static let newlineId: Int32 = 198

    func start(size: ModelSize? = nil, progress: ((Double, String) -> Void)? = nil, completion: (() -> Void)? = nil) {
        if let size { currentModel = size }
        let modelId = currentModel.rawValue
        Task {
            do {
                let start = CFAbsoluteTimeGetCurrent()
                let cacheDir = try HuggingFaceDownloader.getCacheDirectory(for: modelId)

                try await HuggingFaceDownloader.downloadWeights(
                    modelId: modelId,
                    to: cacheDir,
                    additionalFiles: ["vocab.json", "merges.txt", "tokenizer_config.json"],
                    progressHandler: { p in progress?(p * 0.8, "下载文本模型...") }
                )

                progress?(0.85, "加载文本模型...")
                let tok = Qwen3Tokenizer()
                try tok.load(from: cacheDir.appendingPathComponent("vocab.json"))

                let m = QuantizedTextModel(config: currentModel.config)
                try WeightLoader.loadTextDecoderWeights(into: m, from: cacheDir)

                self.tokenizer = tok
                self.model = m
                let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                slog("FillerCleaner 模型加载完成 (\(ms)ms)")
                progress?(1.0, "就绪")
                completion?()
            } catch {
                slog("FillerCleaner 模型加载失败: \(error)")
                completion?()
            }
        }
    }

    func stop() {
        model = nil
        tokenizer = nil
    }

    /// Remove filler words from text using LLM. Returns nil if model not loaded or no change needed.
    func clean(_ text: String) -> String? {
        guard let model, let tokenizer else { return nil }
        guard !text.isEmpty else { return nil }

        let systemPrompt = "去除文本中的填充词（呃、嗯、啊、哦等犹豫词）和重复的字词，保留语气助词，只输出清理后的文本。/no_think"
        let systemTokens = tokenizer.encode(systemPrompt).map { Int32($0) }
        let userTokens = tokenizer.encode(text).map { Int32($0) }

        // Build chat: <|im_start|>system\n{sys}<|im_end|>\n<|im_start|>user\n{text}<|im_end|>\n<|im_start|>assistant\n
        var inputIds: [Int32] = []
        inputIds.append(Self.imStartId)
        inputIds.append(contentsOf: tokenizer.encode("system").map { Int32($0) })
        inputIds.append(Self.newlineId)
        inputIds.append(contentsOf: systemTokens)
        inputIds.append(Self.imEndId)
        inputIds.append(Self.newlineId)

        inputIds.append(Self.imStartId)
        inputIds.append(contentsOf: tokenizer.encode("user").map { Int32($0) })
        inputIds.append(Self.newlineId)
        inputIds.append(contentsOf: userTokens)
        inputIds.append(Self.imEndId)
        inputIds.append(Self.newlineId)

        inputIds.append(Self.imStartId)
        inputIds.append(contentsOf: tokenizer.encode("assistant").map { Int32($0) })
        inputIds.append(Self.newlineId)

        // Prefill
        let inputTensor = MLXArray(inputIds).expandedDimensions(axis: 0)
        let inputEmbeds = model.embedTokens(inputTensor)
        var (hidden, cache) = model(inputsEmbeds: inputEmbeds)

        // Greedy decode
        var generated: [Int32] = []
        let maxTokens = text.count * 3 + 100

        var logits = model.embedTokens.asLinear(hidden[0..., (hidden.dim(1)-1)..<hidden.dim(1), 0...])
        var nextToken = argMax(logits, axis: -1).squeezed().item(Int32.self)
        eval(cache.flatMap { [$0.0, $0.1] })

        for _ in 0..<maxTokens {
            if nextToken == Self.imEndId { break }
            generated.append(nextToken)

            let tokenEmbeds = model.embedTokens(MLXArray([nextToken]).expandedDimensions(axis: 0))
            (hidden, cache) = model(inputsEmbeds: tokenEmbeds, cache: cache)
            logits = model.embedTokens.asLinear(hidden[0..., (-1)..., .ellipsis])
            nextToken = argMax(logits, axis: -1).squeezed().item(Int32.self)
            eval(cache.flatMap { [$0.0, $0.1] })
        }

        let result = tokenizer.decode(tokens: generated.map { Int($0) })
            .trimmingCharacters(in: .whitespacesAndNewlines)
        slog("clean raw (\(generated.count) tokens): \(result.prefix(200))")

        // Strip <think>...</think> blocks if model produces them
        if result.contains("<think>") {
            if let range = result.range(of: "</think>") {
                let afterThink = String(result[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                slog("clean after think: \(afterThink.isEmpty ? "(empty)" : String(afterThink.prefix(100)))")
                return afterThink.isEmpty ? nil : afterThink
            }
            slog("clean: think block not closed, discarded")
            return nil
        }

        return result.isEmpty ? nil : result
    }
}
