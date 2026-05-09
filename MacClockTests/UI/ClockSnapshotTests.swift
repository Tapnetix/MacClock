import Testing
import SwiftUI
import Foundation
@testable import MacClock

/// Visual snapshot tests for the three clock styles. Each test renders a
/// clock view at a fixed `testDate` (so the digits are deterministic) and
/// asserts the PNG matches a committed reference image.
///
/// To re-record references after intentional UI changes:
///   `MACCLOCK_RECORD_SNAPSHOTS=1 swift test`
@MainActor
@Suite("Clock view snapshots")
struct ClockSnapshotTests {
    private let size = CGSize(width: 480, height: 240)

    /// Fixed reference date used for all snapshots: 2026-05-09 13:42:30 UTC.
    /// Picked to exercise both 12h ("1:42") and 24h ("13:42") formats with
    /// non-trivial seconds ("30").
    private static let fixedDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 9
        components.hour = 13
        components.minute = 42
        components.second = 30
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 1_778_420_550)
    }()

    @Test func digitalClockClassic24h() throws {
        let settings = AppSettings.snapshotFixture { s in
            s.use24Hour = true
            s.showSeconds = false
        }
        let view = ClockView(settings: settings, theme: .classicWhite, testDate: Self.fixedDate)
            .background(.black)
        try Snapshot.assert(view, named: "clock_digital_classic_24h", size: size)
    }

    @Test func digitalClockAmber12hWithSeconds() throws {
        let settings = AppSettings.snapshotFixture { s in
            s.use24Hour = false
            s.showSeconds = true
        }
        let view = ClockView(settings: settings, theme: .warmAmber, testDate: Self.fixedDate)
            .background(.black)
        try Snapshot.assert(view, named: "clock_digital_amber_12h_seconds", size: size)
    }

    @Test func analogClock() throws {
        let settings = AppSettings.snapshotFixture { s in
            s.showSeconds = true
        }
        let view = AnalogClockView(settings: settings, theme: .classicWhite, testDate: Self.fixedDate)
            .background(.black)
        try Snapshot.assert(view, named: "clock_analog", size: size)
    }

    @Test func flipClock24h() throws {
        let settings = AppSettings.snapshotFixture { s in
            s.use24Hour = true
            s.showSeconds = false
        }
        let view = FlipClockView(settings: settings, theme: .classicWhite, testDate: Self.fixedDate)
            .background(.black)
        try Snapshot.assert(view, named: "clock_flip_24h", size: size)
    }
}

extension AppSettings {
    /// Builds a deterministic AppSettings backed by an isolated UserDefaults
    /// suite. Each call gets its own suite so tests don't pollute each other.
    @MainActor
    static func snapshotFixture(configure: (AppSettings) -> Void = { _ in }) -> AppSettings {
        let suiteName = "macclock.snapshot.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let settings = AppSettings(defaults: defaults)
        // Sensible defaults for snapshots — small enough to fit a 480×240 canvas.
        settings.clockFontSize = 80
        settings.colorTheme = .classicWhite
        configure(settings)
        return settings
    }
}
