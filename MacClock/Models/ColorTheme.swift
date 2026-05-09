import Foundation
import SwiftUI

enum ColorTheme: String, CaseIterable, Codable {
    case classicWhite = "Classic White"
    case neonBlue = "Neon Blue"
    case warmAmber = "Warm Amber"
    case matrixGreen = "Matrix Green"
    case sunsetRed = "Sunset Red"
    case minimalGray = "Minimal Gray"

    var primaryHex: String {
        switch self {
        case .classicWhite: return "#FFFFFF"
        case .neonBlue: return "#00FFFF"
        case .warmAmber: return "#FFA500"
        case .matrixGreen: return "#00FF00"
        case .sunsetRed: return "#FF6B6B"
        case .minimalGray: return "#CCCCCC"
        }
    }

    var accentHex: String {
        switch self {
        case .classicWhite: return "#AAAAAA"
        case .neonBlue: return "#0066FF"
        case .warmAmber: return "#FFD700"
        case .matrixGreen: return "#006600"
        case .sunsetRed: return "#FF69B4"
        case .minimalGray: return "#888888"
        }
    }

    var primaryColor: Color {
        Color(hex: primaryHex)
    }

    var accentColor: Color {
        Color(hex: accentHex)
    }

    var secondaryOpacity: Double {
        switch self {
        case .classicWhite, .minimalGray:
            return 0.7
        default:
            return 0.8
        }
    }
}

extension Color {
    init(hex: String) {
        // Preserve historical behaviour: invalid input silently produces black.
        // 8-digit hex's alpha byte is intentionally discarded so that themed
        // colour output matches what shipped before this refactor.
        let rgba = HexColor.parse(hex) ?? (0, 0, 0, 1)
        self.init(
            .sRGB,
            red: rgba.red,
            green: rgba.green,
            blue: rgba.blue,
            opacity: 1
        )
    }
}
