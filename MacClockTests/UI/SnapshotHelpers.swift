import Testing
import SwiftUI
import AppKit
import Foundation
@testable import MacClock

/// Snapshot test helper. Renders SwiftUI views to PNG via `ImageRenderer`
/// and compares bytes against a committed reference PNG.
///
/// Modes:
///   - **Compare** (default): if a reference PNG exists, render the view and
///     assert byte equality. On mismatch, write a sibling `*.failed.png` for
///     inspection and record an `Issue`.
///   - **Record-on-first-run**: if no reference exists yet, write the rendered
///     PNG as the new reference and pass silently. This makes onboarding new
///     snapshots painless: write the test, run once, commit the generated PNGs.
///   - **Force-record**: set `MACCLOCK_RECORD_SNAPSHOTS=1` to overwrite all
///     references after intentional UI changes.
///
/// All entry points are `@MainActor` because `ImageRenderer` requires it.
@MainActor
enum Snapshot {
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
    /// PNG and returns. Otherwise compares bytes and records an Issue on mismatch.
    static func assert<V: View>(
        _ view: V,
        named name: String,
        size: CGSize,
        scale: CGFloat = 2.0,
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
        if actual != referenceData {
            // On mismatch, write a *.failed.png sibling so a human can diff.
            let failedURL = referenceURL.deletingPathExtension().appendingPathExtension("failed.png")
            try? actual.write(to: failedURL)
            Issue.record(
                "Snapshot \(name) does not match reference (see \(failedURL.path))",
                sourceLocation: sourceLocation
            )
        }
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
