import Foundation

/// Centralised hex-string → RGBA parser.
///
/// Accepts `"RRGGBB"` and `"RRGGBBAA"` (case-insensitive), optionally prefixed
/// with `#` and/or surrounded by whitespace. Returns `nil` for any other input
/// (wrong length, non-hex characters, empty string).
///
/// Callers that want the historical "silently default to black" behaviour
/// should write `HexColor.parse(hex) ?? (0, 0, 0, 1)`.
enum HexColor {
    static func parse(_ hex: String) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }

        // Reject empty / wrong-length / non-hex input.
        guard sanitized.count == 6 || sanitized.count == 8 else { return nil }
        guard sanitized.allSatisfy({ $0.isHexDigit }) else { return nil }

        var rgba: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgba) else { return nil }

        let red, green, blue, alpha: Double
        if sanitized.count == 8 {
            red   = Double((rgba & 0xFF000000) >> 24) / 255.0
            green = Double((rgba & 0x00FF0000) >> 16) / 255.0
            blue  = Double((rgba & 0x0000FF00) >> 8)  / 255.0
            alpha = Double(rgba & 0x000000FF) / 255.0
        } else {
            red   = Double((rgba & 0xFF0000) >> 16) / 255.0
            green = Double((rgba & 0x00FF00) >> 8)  / 255.0
            blue  = Double(rgba & 0x0000FF) / 255.0
            alpha = 1.0
        }

        return (red, green, blue, alpha)
    }
}
