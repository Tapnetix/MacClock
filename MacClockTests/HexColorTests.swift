import Testing
@testable import MacClock

@Suite("HexColor.parse")
struct HexColorTests {
    @Test func parsesSixDigitHex() {
        let result = HexColor.parse("#FF8800")
        #expect(result != nil)
        #expect(result?.red == 1.0)
        #expect(abs((result?.green ?? 0) - (0x88 / 255.0)) < 1e-9)
        #expect(result?.blue == 0.0)
        #expect(result?.alpha == 1.0)
    }

    @Test func parsesSixDigitHexWithoutHash() {
        let result = HexColor.parse("FF8800")
        #expect(result != nil)
        #expect(result?.red == 1.0)
    }

    @Test func parsesEightDigitHex() {
        // RRGGBBAA — 0xFF, 0x88, 0x00, 0x80 → alpha ≈ 0.502
        let result = HexColor.parse("#FF880080")
        #expect(result != nil)
        #expect(result?.red == 1.0)
        #expect(abs((result?.green ?? 0) - (0x88 / 255.0)) < 1e-9)
        #expect(result?.blue == 0.0)
        #expect(abs((result?.alpha ?? 0) - (0x80 / 255.0)) < 1e-9)
    }

    @Test func trimsWhitespace() {
        let result = HexColor.parse("  #00FF00  ")
        #expect(result != nil)
        #expect(result?.green == 1.0)
    }

    @Test func acceptsLowercase() {
        let result = HexColor.parse("#abcdef")
        #expect(result != nil)
    }

    @Test func rejectsEmptyString() {
        #expect(HexColor.parse("") == nil)
    }

    @Test func rejectsHashOnly() {
        #expect(HexColor.parse("#") == nil)
    }

    @Test func rejectsWrongLength() {
        #expect(HexColor.parse("#FFF") == nil)        // 3
        #expect(HexColor.parse("#FFFF") == nil)       // 4
        #expect(HexColor.parse("#FFFFF") == nil)      // 5
        #expect(HexColor.parse("#FFFFFFF") == nil)    // 7
        #expect(HexColor.parse("#FFFFFFFFF") == nil)  // 9
    }

    @Test func rejectsNonHexCharacters() {
        #expect(HexColor.parse("#GG0000") == nil)
        #expect(HexColor.parse("#12345Z") == nil)
        #expect(HexColor.parse("hello!") == nil)
    }

    @Test func parsesAllZeros() {
        let result = HexColor.parse("#000000")
        #expect(result != nil)
        #expect(result?.red == 0.0)
        #expect(result?.green == 0.0)
        #expect(result?.blue == 0.0)
        #expect(result?.alpha == 1.0)
    }

    @Test func parsesAllOnes() {
        let result = HexColor.parse("#FFFFFF")
        #expect(result?.red == 1.0)
        #expect(result?.green == 1.0)
        #expect(result?.blue == 1.0)
    }
}
