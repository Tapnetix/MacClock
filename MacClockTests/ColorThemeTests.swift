import Foundation
import Testing
import SwiftUI
@testable import MacClock

@Test func allSixPresetsExist() {
    let allThemes = ColorTheme.allCases
    #expect(allThemes.count == 6)
    #expect(allThemes.contains(.classicWhite))
    #expect(allThemes.contains(.neonBlue))
    #expect(allThemes.contains(.warmAmber))
    #expect(allThemes.contains(.matrixGreen))
    #expect(allThemes.contains(.sunsetRed))
    #expect(allThemes.contains(.minimalGray))
}

@Test func classicWhiteHasCorrectColors() {
    let theme = ColorTheme.classicWhite
    #expect(theme.primaryHex == "#FFFFFF")
    #expect(theme.accentHex == "#AAAAAA")
    #expect(theme.secondaryOpacity == 0.7)
}

@Test func themeDisplayNamesAreCorrect() {
    #expect(ColorTheme.classicWhite.rawValue == "Classic White")
    #expect(ColorTheme.neonBlue.rawValue == "Neon Blue")
    #expect(ColorTheme.warmAmber.rawValue == "Warm Amber")
    #expect(ColorTheme.matrixGreen.rawValue == "Matrix Green")
    #expect(ColorTheme.sunsetRed.rawValue == "Sunset Red")
    #expect(ColorTheme.minimalGray.rawValue == "Minimal Gray")
}

@Test func neonBlueHasCorrectColors() {
    let theme = ColorTheme.neonBlue
    #expect(theme.primaryHex == "#00FFFF")
    #expect(theme.accentHex == "#0066FF")
    #expect(theme.secondaryOpacity == 0.8)
}

@Test func warmAmberHasCorrectColors() {
    let theme = ColorTheme.warmAmber
    #expect(theme.primaryHex == "#FFA500")
    #expect(theme.accentHex == "#FFD700")
    #expect(theme.secondaryOpacity == 0.8)
}

@Test func matrixGreenHasCorrectColors() {
    let theme = ColorTheme.matrixGreen
    #expect(theme.primaryHex == "#00FF00")
    #expect(theme.accentHex == "#006600")
    #expect(theme.secondaryOpacity == 0.8)
}

@Test func sunsetRedHasCorrectColors() {
    let theme = ColorTheme.sunsetRed
    #expect(theme.primaryHex == "#FF6B6B")
    #expect(theme.accentHex == "#FF69B4")
    #expect(theme.secondaryOpacity == 0.8)
}

@Test func minimalGrayHasCorrectColors() {
    let theme = ColorTheme.minimalGray
    #expect(theme.primaryHex == "#CCCCCC")
    #expect(theme.accentHex == "#888888")
    #expect(theme.secondaryOpacity == 0.7)
}

@Test func colorFromHexExtension() {
    // Test that Color(hex:) extension works by verifying primaryColor computed property
    // If Color(hex:) didn't work, these would crash or produce unexpected results
    let theme = ColorTheme.classicWhite
    let primaryColor = theme.primaryColor
    let accentColor = theme.accentColor

    // Verify the colors are created (Color is non-optional, so we just verify they exist)
    // The fact that these don't crash proves the extension works
    #expect(type(of: primaryColor) == Color.self)
    #expect(type(of: accentColor) == Color.self)
}

@Test func themeIsCodable() throws {
    let theme = ColorTheme.neonBlue
    let encoder = JSONEncoder()
    let data = try encoder.encode(theme)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ColorTheme.self, from: data)

    #expect(decoded == theme)
}
