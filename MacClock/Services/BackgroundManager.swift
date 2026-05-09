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

/// Image extensions accepted as custom backgrounds. Lowercased.
private let allowedBackgroundExtensions: Set<String> = [
    "jpg", "jpeg", "png", "heic", "heif", "webp"
]

/// Validates that a URL points to an existing, regular image file
/// inside the user's home directory tree (not a symlink escaping it).
/// Returns the resolved canonical URL on success, nil otherwise.
private func validateBackgroundImageURL(_ url: URL) -> URL? {
    let fm = FileManager.default

    // Resolve symlinks so we can see where the path actually points.
    let resolved = url.resolvingSymlinksInPath()

    // Check existence + that it's a regular file, not a directory.
    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: resolved.path, isDirectory: &isDirectory) else { return nil }
    guard !isDirectory.boolValue else { return nil }

    // Extension allowlist.
    let ext = resolved.pathExtension.lowercased()
    guard allowedBackgroundExtensions.contains(ext) else { return nil }

    // Confirm the resolved path lives under the user's home directory tree.
    // (Prevents a symlink in Pictures/ that points to /etc/passwd.)
    let homePath = fm.homeDirectoryForCurrentUser.standardized.path
    guard resolved.standardized.path.hasPrefix(homePath) else { return nil }

    return resolved
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

    func updateBackground(sunrise: Date, sunset: Date, customBookmark: Data?) {
        currentTimeOfDay = timeOfDay(at: Date(), sunrise: sunrise, sunset: sunset)

        if let bookmark = customBookmark, !bookmark.isEmpty {
            loadCustomImage(from: bookmark)
        } else {
            loadBundledImage(for: currentTimeOfDay)
        }
    }

    private func loadCustomImage(from bookmark: Data) {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            // Bookmark unresolvable — fall back to bundled image.
            loadBundledImage(for: currentTimeOfDay)
            return
        }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            loadBundledImage(for: currentTimeOfDay)
            return
        }

        if isDirectory.boolValue {
            loadRandomImageFromFolder(url)
        } else if let validated = validateBackgroundImageURL(url) {
            currentImage = NSImage(contentsOf: validated)
        } else {
            loadBundledImage(for: currentTimeOfDay)
        }
    }

    private func loadRandomImageFromFolder(_ folderURL: URL) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        ) else { return }

        // Filter to allowlisted extensions and validated files.
        let images = contents
            .filter { allowedBackgroundExtensions.contains($0.pathExtension.lowercased()) }
            .compactMap { validateBackgroundImageURL($0) }

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
