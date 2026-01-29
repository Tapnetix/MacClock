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
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
