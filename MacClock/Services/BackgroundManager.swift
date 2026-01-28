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
        let imageName = timeOfDay.defaultImageName

        // Try loading from SPM bundle resources
        // SPM uses Bundle.module for resources, but for executables we need Bundle.main
        if let url = Bundle.main.url(forResource: imageName, withExtension: "jpg", subdirectory: "Backgrounds"),
           let image = NSImage(contentsOf: url) {
            currentImage = image
        } else if let url = Bundle.main.url(forResource: imageName, withExtension: "jpg"),
                  let image = NSImage(contentsOf: url) {
            // Fallback: try without subdirectory
            currentImage = image
        } else if let image = NSImage(named: imageName) {
            // Fallback: try asset catalog
            currentImage = image
        } else {
            // Final fallback: create a solid color placeholder
            currentImage = createPlaceholderImage(for: timeOfDay)
        }
    }

    private func createPlaceholderImage(for timeOfDay: TimeOfDay) -> NSImage {
        let color: NSColor
        switch timeOfDay {
        case .dawn: color = NSColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)  // #FF9966
        case .day: color = NSColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0) // #87CEEB
        case .dusk: color = NSColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0)  // #FF6633
        case .night: color = NSColor(red: 0.1, green: 0.1, blue: 0.44, alpha: 1.0) // #191970
        }

        let size = NSSize(width: 1920, height: 1080)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
}
