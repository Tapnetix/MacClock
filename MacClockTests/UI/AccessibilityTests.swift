import Testing
import SwiftUI
import AppKit
import Foundation
@testable import MacClock

/// Accessibility label coverage tests.
///
/// **Why the design is what it is:** SwiftUI on macOS does not expose its
/// internal accessibility tree through `NSHostingView.accessibilityChildren()`
/// when the view is hosted in a programmatically-constructed (non-key) window.
/// The AX tree is built on demand for system-level VoiceOver queries, not
/// for in-process Swift introspection. The original plan called for walking
/// the tree from `NSHostingView`, but empirically `accessibilityChildren()`
/// returns only platform-internal `CGDrawingView` nodes with no labels.
///
/// **Pragmatic fallback:** since the CR-12 labels are *static strings* in
/// the SwiftUI source, we can guard against accidental removal by reading
/// the source and asserting label presence directly. This is less satisfying
/// than runtime introspection but catches the same regression class —
/// "someone deleted the .accessibilityLabel modifier" — at near-zero cost
/// and zero flakiness.
///
/// **Bonus:** we also exercise the views in `NSHostingView` to ensure they
/// render without crashing under the AX subsystem; the tests assert the AX
/// role of the host view itself is set sensibly.
@MainActor
@Suite("Accessibility labels")
struct AccessibilityTests {
    private static let viewsDir = URL(fileURLWithPath: "\(#filePath)")
        .deletingLastPathComponent()  // .../MacClockTests/UI
        .deletingLastPathComponent()  // .../MacClockTests
        .deletingLastPathComponent()  // .../MacClock (root)
        .appendingPathComponent("MacClock", isDirectory: true)
        .appendingPathComponent("Views", isDirectory: true)

    /// Reads every .swift file under MacClock/Views recursively and returns
    /// concatenated source text. Cached at first call.
    private static let viewsSource: String = {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: viewsDir, includingPropertiesForKeys: nil) else {
            return ""
        }
        var combined = ""
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                combined += text + "\n"
            }
        }
        return combined
    }()

    // MARK: - Source-level label assertions

    /// CR-12: news ticker hover-arrows must have "Previous headline" and
    /// "Next headline" labels.
    @Test func newsTickerNavigationLabelsPresent() {
        let source = Self.viewsSource
        #expect(source.contains("\"Previous headline\""))
        #expect(source.contains("\"Next headline\""))
    }

    /// CR-12: alarm firing view must have "Snooze alarm for X minutes"
    /// (interpolated) and "Dismiss alarm" labels.
    @Test func alarmFiringButtonLabelsPresent() {
        let source = Self.viewsSource
        #expect(source.contains("Snooze alarm for"))
        #expect(source.contains("\"Dismiss alarm\""))
    }

    /// CR-12: weather view must have a content-style label that includes
    /// the temperature and location.
    @Test func weatherContentLabelPresent() {
        let source = Self.viewsSource
        // The label is "Weather: \(temp)°, \(locationName)" or
        // "Weather unavailable" depending on state.
        #expect(source.contains("\"Weather unavailable\""))
        #expect(source.contains("Weather:"))
    }

    /// CR-12: weather chevron must have a "Show/Hide weather details" label
    /// that adapts to state.
    @Test func weatherChevronLabelPresent() {
        let source = Self.viewsSource
        #expect(source.contains("\"Hide weather details\""))
        #expect(source.contains("\"Show weather details\""))
    }

    /// CR-12: world clock items must have a "<city> time" content label.
    @Test func worldClockTimeLabelPresent() {
        let source = Self.viewsSource
        #expect(source.contains(" time\""))
    }

    /// CR-12: clock views must expose "Current time" as the main AX label.
    @Test func clockCurrentTimeLabelPresent() {
        let source = Self.viewsSource
        #expect(source.contains("\"Current time\""))
    }

    // MARK: - Runtime smoke tests
    //
    // These don't introspect the SwiftUI AX subtree (which isn't reachable
    // outside the system AX server) but they verify that the views host
    // cleanly under NSHostingView with AX enabled — i.e. they don't crash
    // when the AX subsystem queries them.

    @Test func alarmFiringViewHostsWithoutCrash() {
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Wake up",
            isEnabled: true,
            repeatDays: [],
            soundName: nil,
            snoozeDuration: 5
        )
        let view = AlarmFiringView(
            alarm: alarm,
            onDismiss: {},
            onSnooze: {},
            theme: .classicWhite,
            snoozeCount: 0,
            maxSnoozes: 10
        )
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 480, height: 480)
        host.layoutSubtreeIfNeeded()
        // The host view itself reports as an AXGroup once the SwiftUI
        // subtree is laid out.
        #expect((host as AnyObject).accessibilityRole?() == .group)
    }

    @Test func newsTickerHostsWithoutCrash() {
        let settings = AppSettings.snapshotFixture { s in
            s.newsTickerStyle = .rotating
        }
        let view = NewsTickerView(settings: settings, theme: .classicWhite, newsItems: [])
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 480, height: 30)
        host.layoutSubtreeIfNeeded()
        #expect((host as AnyObject).accessibilityRole?() == .group)
    }

    @Test func weatherViewHostsWithoutCrash() {
        let settings = AppSettings.snapshotFixture { _ in }
        let view = WeatherView(
            weather: nil,
            useCelsius: true,
            settings: settings,
            theme: .classicWhite,
            showDetailPanel: .constant(false)
        )
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 320, height: 80)
        host.layoutSubtreeIfNeeded()
        #expect((host as AnyObject).accessibilityRole?() == .group)
    }

    @Test func worldClockItemHostsWithoutCrash() {
        let clock = WorldClock(id: UUID(), cityName: "London", timezoneIdentifier: "Europe/London")
        let view = WorldClockItem(
            clock: clock,
            theme: .classicWhite,
            use24Hour: true,
            showAbbreviation: false,
            showDayDiff: false,
            compact: true,
            testDate: Date(timeIntervalSince1970: 1_778_420_550)
        )
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 160, height: 80)
        host.layoutSubtreeIfNeeded()
        #expect((host as AnyObject).accessibilityRole?() == .group)
    }
}
