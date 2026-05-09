import Foundation
import OSLog

/// A simple file-backed JSON cache for Codable values.
/// Stored under `~/Library/Caches/<bundle-id>/` so the OS may purge under pressure
/// and the data sits in the conventional location for transient user data
/// (rather than `~/Library/Preferences`, which is for user preferences).
///
/// - Atomic writes: `Data.write(to:options:.atomic)` writes to a tmp file then renames.
/// - Corruption recovery: on decode failure, the file is deleted and `nil` is returned.
/// - TTL: optional; expired entries return `nil` and the file is left in place
///   (so a write failure doesn't blow away an otherwise-valid cache).
final class Cache<T: Codable> {
    private let fileURL: URL
    private let ttl: TimeInterval?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MacClock", category: "Cache")

    /// - Parameters:
    ///   - filename: bare filename (e.g. `"icalEvents.json"`); appended to the cache directory.
    ///   - ttl: optional TTL. `nil` means "no expiry — caller decides freshness".
    init?(filename: String, ttl: TimeInterval? = nil) {
        guard let dir = Self.cacheDirectory() else { return nil }
        self.fileURL = dir.appendingPathComponent(filename)
        self.ttl = ttl
    }

    func load() -> T? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        // TTL check (against file mtime)
        if let ttl, let mtime = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date {
            if Date().timeIntervalSince(mtime) > ttl {
                return nil
            }
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            logger.error("Cache read failed for \(self.fileURL.lastPathComponent, privacy: .public)")
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // Corrupt or schema-mismatched file — delete so a future write can succeed.
            logger.error("Cache decode failed for \(self.fileURL.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public). Deleting.")
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
    }

    func save(_ value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Cache write failed for \(self.fileURL.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Returns the per-bundle cache directory, creating it if necessary.
    /// Visible to tests via `@testable import`.
    static func cacheDirectory() -> URL? {
        let fm = FileManager.default
        guard let base = try? fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            return nil
        }
        let bundleID = Bundle.main.bundleIdentifier ?? "com.local.MacClock"
        let dir = base.appendingPathComponent(bundleID, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            do {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                return nil
            }
        }
        return dir
    }
}
