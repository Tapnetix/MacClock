import Foundation
import SwiftUI
import AppKit

enum TimeOfDay: String, CaseIterable {
    case dawn
    case day
    case dusk
    case night

    var defaultImageName: String {
        switch self {
        case .dawn: return "bg_dawn"
        case .day: return "bg_day"
        case .dusk: return "bg_dusk"
        case .night: return "bg_night"
        }
    }
}

@Observable
final class BackgroundManager {
    var currentTimeOfDay: TimeOfDay = .day
    var currentImage: NSImage?

    private var customImagePath: String?
    private var customFolderImages: [URL] = []

    func timeOfDay(at date: Date, sunrise: Date, sunset: Date) -> TimeOfDay {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute

        let sunriseHour = calendar.component(.hour, from: sunrise)
        let sunriseMinute = calendar.component(.minute, from: sunrise)
        let sunriseMinutes = sunriseHour * 60 + sunriseMinute

        let sunsetHour = calendar.component(.hour, from: sunset)
        let sunsetMinute = calendar.component(.minute, from: sunset)
        let sunsetMinutes = sunsetHour * 60 + sunsetMinute

        // Dawn: 1 hour before sunrise to sunrise
        if currentMinutes >= sunriseMinutes - 60 && currentMinutes < sunriseMinutes {
            return .dawn
        }
        // Day: sunrise to 1 hour before sunset
        if currentMinutes >= sunriseMinutes && currentMinutes < sunsetMinutes - 60 {
            return .day
        }
        // Dusk: 1 hour before sunset to 1 hour after sunset
        if currentMinutes >= sunsetMinutes - 60 && currentMinutes < sunsetMinutes + 60 {
            return .dusk
        }
        // Night: everything else
        return .night
    }

    func updateBackground(sunrise: Date, sunset: Date, customPath: String?) {
        currentTimeOfDay = timeOfDay(at: Date(), sunrise: sunrise, sunset: sunset)

        if let path = customPath, !path.isEmpty {
            loadCustomImage(from: path)
        } else {
            loadBundledImage(for: currentTimeOfDay)
        }
    }

    private func loadCustomImage(from path: String) {
        let url = URL(fileURLWithPath: path)
        var isDirectory: ObjCBool = false

        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Load random image from folder
                loadRandomImageFromFolder(url)
            } else {
                // Load single image
                currentImage = NSImage(contentsOf: url)
            }
        }
    }

    private func loadRandomImageFromFolder(_ folderURL: URL) {
        let imageExtensions = ["jpg", "jpeg", "png", "heic"]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        ) else { return }

        let images = contents.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
        if let randomImage = images.randomElement() {
            currentImage = NSImage(contentsOf: randomImage)
        }
    }

    private func loadBundledImage(for timeOfDay: TimeOfDay) {
        // Load from asset catalog or bundled resources
        if let image = NSImage(named: timeOfDay.defaultImageName) {
            currentImage = image
        }
    }
}
