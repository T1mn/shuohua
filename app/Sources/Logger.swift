import Foundation

private let logFile: FileHandle? = {
    let path = "/tmp/shuohua.log"
    FileManager.default.createFile(atPath: path, contents: nil)
    return FileHandle(forWritingAtPath: path)
}()

func slog(_ msg: String) {
    let line = "[shuohua] \(msg)\n"
    print(line, terminator: "")
    logFile?.seekToEndOfFile()
    logFile?.write(line.data(using: .utf8)!)
}
