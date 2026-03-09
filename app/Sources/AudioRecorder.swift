import AVFoundation

class AudioRecorder {
    private let engine = AVAudioEngine()
    private var buffer = [Float]()
    private let lock = NSLock()
    private var tapCallCount = 0

    func start() throws {
        // 请求麦克风权限
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status != .authorized {
            slog("麦克风权限状态: \(status.rawValue)")
            if status == .notDetermined {
                let semaphore = DispatchSemaphore(value: 0)
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    slog("麦克风权限请求结果: \(granted)")
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }

        // 重置状态
        tapCallCount = 0
        if engine.isRunning {
            engine.stop()
        }
        engine.reset()
        slog("engine 已重置")

        let input = engine.inputNode
        let hwFormat = input.outputFormat(forBus: 0)
        slog("音频格式: \(hwFormat.sampleRate)Hz, \(hwFormat.channelCount)ch")

        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 16000, channels: 1, interleaved: false)!

        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            throw NSError(domain: "shuohua", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot create audio converter"])
        }

        input.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] pcmBuffer, _ in
            guard let self else { return }
            self.tapCallCount += 1
            if self.tapCallCount <= 3 {
                slog("tap回调#\(self.tapCallCount): frameLength=\(pcmBuffer.frameLength)")
            }
            let ratio = targetFormat.sampleRate / hwFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(pcmBuffer.frameLength) * ratio) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

            var error: NSError?
            converter.convert(to: converted, error: &error) { _, status in
                status.pointee = .haveData
                return pcmBuffer
            }
            if let error = error {
                slog("转换错误: \(error)")
                return
            }
            guard let floats = converted.floatChannelData?[0] else {
                slog("无法获取音频数据")
                return
            }

            let samples = Array(UnsafeBufferPointer(start: floats, count: Int(converted.frameLength)))
            self.lock.lock()
            self.buffer.append(contentsOf: samples)
            self.lock.unlock()
        }

        engine.prepare()
        try engine.start()
        slog("录音开始, engine.isRunning=\(engine.isRunning)")
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
