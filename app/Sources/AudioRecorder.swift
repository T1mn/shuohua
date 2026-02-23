import AVFoundation

class AudioRecorder {
    private let engine = AVAudioEngine()
    private var buffer = [Float]()
    private let lock = NSLock()

    func start() throws {
        let input = engine.inputNode
        let hwFormat = input.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 16000, channels: 1, interleaved: false)!

        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            throw NSError(domain: "shuohua", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot create audio converter"])
        }

        input.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] pcmBuffer, _ in
            guard let self else { return }
            let ratio = targetFormat.sampleRate / hwFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(pcmBuffer.frameLength) * ratio) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

            var error: NSError?
            converter.convert(to: converted, error: &error) { _, status in
                status.pointee = .haveData
                return pcmBuffer
            }
            guard error == nil, let floats = converted.floatChannelData?[0] else { return }

            let samples = Array(UnsafeBufferPointer(start: floats, count: Int(converted.frameLength)))
            self.lock.lock()
            self.buffer.append(contentsOf: samples)
            self.lock.unlock()
        }

        try engine.start()
        slog("录音开始")
    }

    func stop() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        lock.lock()
        let result = buffer
        buffer.removeAll()
        lock.unlock()
        let duration = Double(result.count) / 16000.0
        slog("录音停止, 采样数: \(result.count), 时长: \(String(format: "%.1f", duration))s")
        return result
    }
}
