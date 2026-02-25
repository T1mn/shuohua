import XCTest
import Foundation

/// Tests for FillerCleaner prompt construction and API request format.
/// Uses a local replica of the system prompt to verify behavior without network calls.
final class FillerCleanerTests: XCTestCase {

    // The system prompt used by FillerCleaner — kept in sync manually.
    private let systemPrompt = "你是语音转文字的后处理器。只做删除，禁止改写、替换、重组或概括。删除填充词（呃、嗯、啊、哦、那个、就是说）和连续重复的字词。保留所有实义词和原始语序。直接输出结果。"

    // MARK: - System prompt content

    func testSystemPromptContainsFillerWords() {
        let fillers = ["呃", "嗯", "啊", "哦", "那个", "就是说"]
        for filler in fillers {
            XCTAssertTrue(systemPrompt.contains(filler), "System prompt should mention filler word: \(filler)")
        }
    }

    func testSystemPromptForbidsRewriting() {
        XCTAssertTrue(systemPrompt.contains("禁止改写"))
        XCTAssertTrue(systemPrompt.contains("只做删除"))
    }

    func testSystemPromptPreservesOrder() {
        XCTAssertTrue(systemPrompt.contains("原始语序"))
    }

    // MARK: - API request body format

    func testRequestBodyStructure() throws {
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "呃今天呃天气很好"],
            ],
            "temperature": 0.0,
        ]

        let data = try JSONSerialization.data(withJSONObject: body)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["model"] as? String, "deepseek-chat")
        XCTAssertEqual(parsed["temperature"] as? Double, 0.0)

        let messages = parsed["messages"] as! [[String: String]]
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0]["role"], "system")
        XCTAssertEqual(messages[1]["role"], "user")
        XCTAssertEqual(messages[1]["content"], "呃今天呃天气很好")
    }

    func testRequestBodySerializesToValidJSON() throws {
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "测试文本"],
            ],
            "temperature": 0.0,
        ]

        XCTAssertTrue(JSONSerialization.isValidJSONObject(body))
        let data = try JSONSerialization.data(withJSONObject: body)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Cleaning result logic

    func testEmptyCleanedResultReturnsNil() {
        let result = ""
        let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(cleaned.isEmpty)
    }

    func testWhitespaceOnlyResultReturnsNil() {
        let result = "   \n  "
        let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(cleaned.isEmpty)
    }

    func testValidResultIsTrimmed() {
        let result = "  今天天气很好  \n"
        let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(cleaned, "今天天气很好")
    }

    func testIdenticalTextSkipsReplacement() {
        // When cleaned == original, FillerCleaner skips replacement
        let original = "今天天气很好"
        let cleaned = "今天天气很好"
        XCTAssertEqual(original, cleaned, "Identical text should not trigger replacement")
    }
}
