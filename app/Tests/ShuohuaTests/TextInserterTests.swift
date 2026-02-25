import XCTest

final class TextInserterTests: XCTestCase {

    // MARK: - String.count (Character count, user-perceived)

    func testChineseCharacterCount() {
        let text = "你好世界"
        XCTAssertEqual(text.count, 4)
    }

    func testMixedChineseEnglishCount() {
        let text = "hello你好"
        XCTAssertEqual(text.count, 7)
    }

    func testChineseWithPunctuation() {
        let text = "你好，世界！"
        XCTAssertEqual(text.count, 6)
    }

    func testEmptyString() {
        XCTAssertEqual("".count, 0)
        XCTAssertEqual("".utf16.count, 0)
    }

    // MARK: - String.utf16.count (relevant for CGEvent unicode insertion)

    func testChineseUTF16Count() {
        // CJK characters are single UTF-16 code units
        let text = "你好世界"
        XCTAssertEqual(text.utf16.count, 4)
    }

    func testASCIIUTF16Count() {
        let text = "hello"
        XCTAssertEqual(text.utf16.count, 5)
    }

    func testMixedUTF16Count() {
        let text = "hello你好"
        XCTAssertEqual(text.utf16.count, 7)
    }

    // MARK: - Emoji edge cases

    func testSimpleEmojiCount() {
        // A simple emoji is 1 Character but may be >1 UTF-16 code unit
        let emoji = "😀"
        XCTAssertEqual(emoji.count, 1)
        XCTAssertEqual(emoji.utf16.count, 2) // surrogate pair
    }

    func testFlagEmojiCount() {
        let flag = "🇨🇳"
        XCTAssertEqual(flag.count, 1)
        XCTAssertEqual(flag.utf16.count, 4) // two regional indicators
    }

    func testFamilyEmojiCount() {
        // Family emoji joined with ZWJ
        let family = "👨‍👩‍👧"
        XCTAssertEqual(family.count, 1)
        XCTAssertGreaterThan(family.utf16.count, 1)
    }

    func testEmojiMixedWithChinese() {
        let text = "你好😀世界"
        XCTAssertEqual(text.count, 5)
        // 4 CJK (1 each) + 1 emoji (2 utf16) = 6
        XCTAssertEqual(text.utf16.count, 6)
    }

    // MARK: - Edge cases for the replace mechanism

    func testSingleCharacterString() {
        let text = "啊"
        XCTAssertEqual(text.count, 1)
        XCTAssertEqual(text.utf16.count, 1)
    }

    func testWhitespaceAndNewlines() {
        let text = "你好\n世界"
        XCTAssertEqual(text.count, 5) // includes newline as a character
        XCTAssertEqual(text.utf16.count, 5)
    }

    func testFullWidthPunctuation() {
        // Full-width punctuation common in Chinese text
        let text = "，。！？"
        XCTAssertEqual(text.count, 4)
        XCTAssertEqual(text.utf16.count, 4)
    }
}
