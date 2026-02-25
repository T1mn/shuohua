import XCTest
import Foundation

// Local struct matching the DeepSeek API chat completion response format.
// Defined here so tests don't depend on the executable target.
private struct DeepSeekResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]

    var cleanedText: String? {
        guard let content = choices.first?.message.content else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

final class DeepSeekResponseTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - Valid response parsing

    func testParseValidResponse() throws {
        let json = """
        {
            "choices": [{"message": {"content": "cleaned text"}}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeepSeekResponse.self, from: json)
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices.first?.message.content, "cleaned text")
        XCTAssertEqual(response.cleanedText, "cleaned text")
    }

    func testParseChineseContent() throws {
        let json = """
        {
            "choices": [{"message": {"content": "今天天气很好"}}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeepSeekResponse.self, from: json)
        XCTAssertEqual(response.cleanedText, "今天天气很好")
    }

    func testParseMultipleChoices() throws {
        let json = """
        {
            "choices": [
                {"message": {"content": "first"}},
                {"message": {"content": "second"}}
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeepSeekResponse.self, from: json)
        XCTAssertEqual(response.choices.count, 2)
        // cleanedText uses the first choice
        XCTAssertEqual(response.cleanedText, "first")
    }

    // MARK: - Empty and whitespace content

    func testEmptyContentReturnsNil() throws {
        let json = """
        {
            "choices": [{"message": {"content": ""}}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeepSeekResponse.self, from: json)
        XCTAssertNil(response.cleanedText)
    }

    func testWhitespaceOnlyContentReturnsNil() throws {
        let json = """
        {
            "choices": [{"message": {"content": "   \\n  "}}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeepSeekResponse.self, from: json)
        XCTAssertNil(response.cleanedText)
    }

    func testEmptyChoicesReturnsNil() throws {
        let json = """
        {
            "choices": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeepSeekResponse.self, from: json)
        XCTAssertNil(response.cleanedText)
    }

    // MARK: - Malformed / missing fields

    func testMissingChoicesFieldThrows() {
        let json = """
        {
            "id": "chatcmpl-123"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(DeepSeekResponse.self, from: json))
    }

    func testMissingMessageFieldThrows() {
        let json = """
        {
            "choices": [{"index": 0}]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(DeepSeekResponse.self, from: json))
    }

    func testMissingContentFieldThrows() {
        let json = """
        {
            "choices": [{"message": {"role": "assistant"}}]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(DeepSeekResponse.self, from: json))
    }

    func testInvalidJSONThrows() {
        let json = "not json at all".data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(DeepSeekResponse.self, from: json))
    }

    // MARK: - Content with extra whitespace is trimmed

    func testContentTrimsWhitespace() throws {
        let json = """
        {
            "choices": [{"message": {"content": "  hello world  \\n"}}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(DeepSeekResponse.self, from: json)
        XCTAssertEqual(response.cleanedText, "hello world")
    }
}
