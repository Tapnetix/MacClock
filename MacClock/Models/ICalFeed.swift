import Foundation
import SwiftUI

struct ICalFeed: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var isEnabled: Bool
    var colorHex: String

    struct ColorPreset: Identifiable {
        let id = UUID()
        let name: String
        let hex: String
    }

    static let colorPresets: [ColorPreset] = [
        ColorPreset(name: "Red", hex: "#FF3B30"),
        ColorPreset(name: "Orange", hex: "#FF9500"),
        ColorPreset(name: "Yellow", hex: "#FFCC00"),
        ColorPreset(name: "Green", hex: "#34C759"),
        ColorPreset(name: "Blue", hex: "#007AFF"),
        ColorPreset(name: "Purple", hex: "#AF52DE"),
        ColorPreset(name: "Pink", hex: "#FF2D55"),
        ColorPreset(name: "Gray", hex: "#8E8E93"),
    ]
}
