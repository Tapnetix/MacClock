import Testing
import SwiftUI
import AppKit
import Foundation
@testable import MacClock

/// Snapshot test helper. Renders SwiftUI views to PNG via `ImageRenderer`
/// and compares them against a committed reference PNG.
///
/// **Comparison strategy:** perceptual / tile-average hash, not strict byte
/// equality. ImageRenderer can produce a few bytes of jitter when tests run
/// in parallel (PNG compression is not always deterministic, and font
/// rasterisation has subpixel variance). We downsample both images to an
/// 8×8 grayscale grid and compare per-tile averages with a small epsilon.
/// This catches real visual regressions while tolerating noise.
///
/// Modes:
///   - **Compare** (default): if a reference PNG exists, render and compare.
///     On mismatch, write a sibling `*.failed.png` for inspection and record
///     an `Issue`.
///   - **Record-on-first-run**: if no reference exists yet, write the rendered
///     PNG as the new reference and pass silently. Makes onboarding new
///     snapshots painless: write the test, run once, commit the generated PNGs.
///   - **Force-record**: set `MACCLOCK_RECORD_SNAPSHOTS=1` to overwrite all
///     references after intentional UI changes.
///
/// All entry points are `@MainActor` because `ImageRenderer` requires it.
@MainActor
enum Snapshot {
    /// Default comparison tolerance. Each tile's grayscale average can drift
    /// by up to this fraction (0.04 = 4%) before the snapshot is considered
    /// changed. Tuned empirically — typical jitter is < 0.5%, real visual
    /// changes (theme/text/layout) easily exceed 4%.
    static let defaultTolerance: Double = 0.04

    /// Renders a SwiftUI view to PNG bytes at a fixed size and scale.
    /// Returns `nil` if the renderer or bitmap conversion fails.
    static func png<V: View>(of view: V, size: CGSize, scale: CGFloat = 2.0) -> Data? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = scale
        guard let nsImage = renderer.nsImage else { return nil }
        guard let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    /// Asserts the rendered view matches the reference PNG with the given name.
    /// On first run (no reference exists) or in record mode, writes the rendered
    /// PNG and returns. Otherwise compares with a perceptual hash and records
    /// an Issue on mismatch.
    static func assert<V: View>(
        _ view: V,
        named name: String,
        size: CGSize,
        scale: CGFloat = 2.0,
        tolerance: Double = defaultTolerance,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let actualData = png(of: view, size: size, scale: scale)
        let actual = try #require(actualData, "ImageRenderer returned nil for \(name)", sourceLocation: sourceLocation)

        let referenceURL = referenceURL(for: name)
        let recordMode = ProcessInfo.processInfo.environment["MACCLOCK_RECORD_SNAPSHOTS"] == "1"

        if recordMode || !FileManager.default.fileExists(atPath: referenceURL.path) {
            try FileManager.default.createDirectory(
                at: referenceURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try actual.write(to: referenceURL)
            // First-run / record-mode: succeed silently. Re-runs will compare.
            return
        }

        let referenceData = try Data(contentsOf: referenceURL)
        let drift = perceptualDrift(actual: actual, reference: referenceData)

        if drift > tolerance {
            // On mismatch, write a *.failed.png sibling so a human can diff.
            let failedURL = referenceURL.deletingPathExtension().appendingPathExtension("failed.png")
            try? actual.write(to: failedURL)
            Issue.record(
                "Snapshot \(name) drift \(String(format: "%.4f", drift)) exceeds tolerance \(tolerance) (see \(failedURL.path))",
                sourceLocation: sourceLocation
            )
        }
    }

    /// Computes the maximum per-tile grayscale-average drift between two PNGs,
    /// downsampled to an 8×8 grid. Returns 1.0 if either side fails to decode.
    /// A return value of 0.0 means the images are perceptually identical at
    /// the 8×8 granularity. Real layout/text/colour changes typically push
    /// this above 0.05.
    static func perceptualDrift(actual: Data, reference: Data) -> Double {
        guard let actualHash = tileHash(of: actual),
              let referenceHash = tileHash(of: reference),
              actualHash.count == referenceHash.count else {
            return 1.0
        }
        var maxDelta: Double = 0
        for i in 0..<actualHash.count {
            let delta = abs(actualHash[i] - referenceHash[i])
            if delta > maxDelta { maxDelta = delta }
        }
        return maxDelta
    }

    /// Decodes PNG data and returns an 8×8 grid of normalised grayscale
    /// averages (each in [0, 1]). Returns nil on decode failure.
    private static let tileGrid = 8

    private static func tileHash(of pngData: Data) -> [Double]? {
        guard let bitmap = NSBitmapImageRep(data: pngData) else { return nil }
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        guard width > 0, height > 0 else { return nil }

        var averages = [Double](repeating: 0, count: tileGrid * tileGrid)
        var counts = [Int](repeating: 0, count: tileGrid * tileGrid)

        // Sample a fixed grid of pixels for speed and stability. We don't
        // need full coverage to detect macroscopic changes.
        let samples = 64 // per axis
        for sy in 0..<samples {
            for sx in 0..<samples {
                let px = (sx * width) / samples
                let py = (sy * height) / samples
                guard let color = bitmap.colorAt(x: px, y: py) else { continue }
                let gray = Double(0.299 * color.redComponent + 0.587 * color.greenComponent + 0.114 * color.blueComponent)
                let tx = (sx * tileGrid) / samples
                let ty = (sy * tileGrid) / samples
                let idx = ty * tileGrid + tx
                averages[idx] += gray
                counts[idx] += 1
            }
        }

        for i in 0..<averages.count where counts[i] > 0 {
            averages[i] /= Double(counts[i])
        }
        return averages
    }

    /// Returns the absolute URL of a named reference PNG inside
    /// `MacClockTests/UI/Snapshots/`. Uses `#filePath` to anchor to the test
    /// source location so the path is stable across machines.
    private static func referenceURL(for name: String, file: StaticString = #filePath) -> URL {
        // #filePath here is the path of *this* file (SnapshotHelpers.swift),
        // i.e. .../MacClockTests/UI/SnapshotHelpers.swift. Strip the filename
        // and append "Snapshots/<name>.png".
        let helperFile = URL(fileURLWithPath: "\(file)")
        let snapshotsDir = helperFile.deletingLastPathComponent().appendingPathComponent("Snapshots", isDirectory: true)
        return snapshotsDir.appendingPathComponent("\(name).png")
    }
}
