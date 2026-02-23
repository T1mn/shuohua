import Foundation
import Qwen3ASR
import Qwen3Common

class ASREngine {
    private var model: Qwen3ASRModel?
    private static let maxChunkSamples = 25 * 16000  // 25s per chunk

    var isLoaded: Bool { model != nil }

    func loadModel(
        progress: ((Double, String) -> Void)? = nil,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        let start = CFAbsoluteTimeGetCurrent()
        Task {
            do {
                let m = try await Qwen3ASRModel.fromPretrained(
                    modelId: "mlx-community/Qwen3-ASR-0.6B-4bit",
                    progressHandler: progress
                )
                self.model = m
                let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                completion(.success(ms))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Transcribe with auto-chunking for long audio, calls onChunk after each segment
    func transcribe(
        samples: [Float],
        sampleRate: Int = 16000,
        onChunk: ((String) -> Void)? = nil
    ) -> (text: String, durationMs: Int) {
        guard let model else { return ("", 0) }
        let start = CFAbsoluteTimeGetCurrent()
        var fullText = ""

        let chunks = stride(from: 0, to: samples.count, by: Self.maxChunkSamples).map {
            Array(samples[$0..<min($0 + Self.maxChunkSamples, samples.count)])
        }

        for chunk in chunks {
            let text = model.transcribe(audio: chunk, sampleRate: sampleRate)
            fullText += text
            onChunk?(text)
        }

        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        return (fullText, ms)
    }
}
