import XCTest
@testable import OrderedPlistEncoder

private struct X: Codable, Hashable {
    let b: String
    let a: Int
    let c: Int
}

private struct DictWrapper: Codable, Hashable {
    let inner: [String: Int]
}

@available(macOS 13.0, *)
final class OrderedPlistEncoderTests: XCTestCase {
    func testRoundtrips() throws {
        try assertRoundtrips(23)
        try assertRoundtrips(-9)
        try assertRoundtrips(4.5)
        try assertRoundtrips("Test this")
        try assertRoundtrips(" a string with  \nspaces and stuff   ")
        try assertRoundtrips([1, -9, 3])
        try assertRoundtrips(["hello": "a", "world": "b"])
        try assertRoundtrips(true)
        try assertRoundtrips(X(b: "abc", a: 3, c: -9))
    }

    func testCompactElements() throws {
        let encoder = OrderedPlistEncoder()
        XCTAssertEqual(stripPrologue(try encoder.encodeToString(true)), wrapInPlist("<true/>"))
        XCTAssertEqual(stripPrologue(try encoder.encodeToString(true)), wrapInPlist("<true/>"))
    }

    func testKeyOrder() throws {
        let encoder = OrderedPlistEncoder()
        XCTAssertEqual(stripPrologue(try encoder.encodeToString(X(b: "a", a: -1, c: 0))), wrapInPlist("<dict><key>b</key><string>a</string><key>a</key><integer>-1</integer><key>c</key><integer>0</integer></dict>"))
    }

    func testDictKeyOrder() throws {
        let encoder = OrderedPlistEncoder()
        let obj = DictWrapper(inner: ["c": 1, "a": 1, "b": 1])
        let enc = stripPrologue(try encoder.encodeToString(obj))
        let exp = wrapInPlist("<dict><key>inner</key><dict><key>a</key><integer>1</integer><key>b</key><integer>1</integer><key>c</key><integer>1</integer></dict></dict>")
        XCTAssertEqual(exp, enc)
    }

    private func assertRoundtrips<Value>(_ value: Value, line: UInt = #line) throws where Value: Codable & Equatable {
        let encoder = OrderedPlistEncoder()
        let decoder = PropertyListDecoder()
        let roundtripped = try decoder.decode(Value.self, from: encoder.encode(value))
        XCTAssertEqual(roundtripped, value, line: line)
    }

    private func wrapInPlist(_ xml: String) -> String {
        """
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">\(xml)</plist>
        """
    }

    private func stripPrologue(_ xml: String) -> String {
        xml.replacing(try! Regex(#"<\?xml[^\?]+\?>"#), with: "")
           .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
