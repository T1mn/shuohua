import AVFoundation
import Accelerate

class AudioRecorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private var audioOutput: AVCaptureAudioDataOutput?
    private var buffer = [Float]()
    private let lock = NSLock()
    private let audioQueue = DispatchQueue(label: "audio.capture.queue")
    private var callbackCount = 0
    private var actualSampleRate: Double = 48000.0

    func start() throws {
        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw NSError(domain: "shuohua", code: 1, userInfo: [NSLocalizedDescriptionKey: "No audio device"])
        }
        slog("✓ 获取到音频设备: \(device.localizedName)")

        let input = try AVCaptureDeviceInput(device: device)
        slog("✓ 创建音频输入")

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            slog("✓ 添加输入到会话")
        } else {
            slog("✗ 无法添加输入")
        }

        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: audioQueue)
        slog("✓ 创建音频输出，设置 delegate")

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            slog("✓ 添加输出到会话")
        } else {
            slog("✗ 无法添加输出")
        }

        audioOutput = output
        callbackCount = 0
        captureSession.startRunning()
        slog("✓ 会话已启动，isRunning=\(captureSession.isRunning)")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        callbackCount += 1
        if callbackCount == 1 {
            if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
                let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)?.pointee
                actualSampleRate = asbd?.mSampleRate ?? 48000.0
                slog("✓ captureOutput 首次被调用")
                slog("  音频格式: sampleRate=\(actualSampleRate), channels=\(asbd?.mChannelsPerFrame ?? 0), bitsPerChannel=\(asbd?.mBitsPerChannel ?? 0)")
            }
        }

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

        guard let data = dataPointer else { return }

        // 音频是 Float32 格式
        let floatPointer = data.withMemoryRebound(to: Float.self, capacity: length / 4) { $0 }
        let sampleCount = length / 4
        let floatSamples = Array(UnsafeBufferPointer(start: floatPointer, count: sampleCount))

        lock.lock()
        buffer.append(contentsOf: floatSamples)
        lock.unlock()
    }

    func stop() -> [Float] {
        captureSession.stopRunning()
        lock.lock()
        let result = buffer
        buffer.removeAll()
        lock.unlock()

        // 从 48kHz 重采样到 16kHz
        let resampled = resample(samples: result, fromRate: actualSampleRate, toRate: 16000.0)
        let duration = Double(resampled.count) / 16000.0
        slog("录音停止: 原始采样数=\(result.count), 重采样后=\(resampled.count), 时长=\(String(format: "%.1f", duration))s, 回调次数=\(callbackCount)")

        if !resampled.isEmpty {
            saveAsWAV(samples: resampled, path: "/tmp/shuohua_recording.wav", sampleRate: 16000)
        }

        return resampled
    }

    private func resample(samples: [Float], fromRate: Double, toRate: Double) -> [Float] {
        if samples.isEmpty { return [] }
        let ratio = fromRate / toRate
        let outputCount = Int(Double(samples.count) / ratio)
        var output = [Float](repeating: 0, count: outputCount)
        
        for i in 0..<outputCount {
            let srcIndex = Double(i) * ratio
            let index = Int(srcIndex)
            if index < samples.count - 1 {
                let frac = Float(srcIndex - Double(index))
                output[i] = samples[index] * (1 - frac) + samples[index + 1] * frac
            } else if index < samples.count {
                output[i] = samples[index]
            }
        }
        return output
    }

    private func saveAsWAV(samples: [Float], path: String, sampleRate: Int) {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16

        var int16Samples = [Int16]()
        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            int16Samples.append(Int16(clamped * 32767.0))
        }

        let dataSize = int16Samples.count * 2
        var data = Data()

        // RIFF header
        data.append("RIFF".data(using: .ascii)!)
        data.append(withUnsafeBytes(of: Int32(36 + dataSize).littleEndian) { Data($0) })
        data.append("WAVE".data(using: .ascii)!)

        // fmt chunk
        data.append("fmt ".data(using: .ascii)!)
        data.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: (Int32(sampleRate) * Int32(numChannels) * Int32(bitsPerSample) / 8).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: (numChannels * bitsPerSample / 8).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        // data chunk
        data.append("data".data(using: .ascii)!)
        data.append(withUnsafeBytes(of: Int32(dataSize).littleEndian) { Data($0) })
        for sample in int16Samples {
            data.append(withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }

        do {
            try data.write(to: URL(fileURLWithPath: path))
            slog("✓ 音频已保存: \(path)")
        } catch {
            slog("✗ 保存音频失败: \(error)")
        }
    }
}
