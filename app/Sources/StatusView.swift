import SwiftUI

struct StatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("说话 Shuohua").font(.headline)
            Text("模型: Qwen3-ASR-0.6B-4bit")
                .font(.caption)
            Text("双击 Ctrl 开始/停止录音")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300)
    }
}
