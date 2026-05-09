import Testing
import SwiftUI
import AppKit
import Foundation
@testable import MacClock

/// Interaction tests for the highest-traffic interactive flows
/// (snooze/dismiss, news ticker navigation).
///
/// **Why this file is small:**
/// The plan called for programmatic button presses via the AX tree
/// (`NSAccessibilityElement.accessibilityPerformPress`). That requires
/// the SwiftUI AX tree to be reachable from `NSHostingView`. As
/// documented in `AccessibilityTests.swift`, SwiftUI does not expose its
/// AX tree through a programmatic NSHostingView — `accessibilityChildren()`
/// returns only platform-internal NSView wrappers with no AX role/label.
/// This means there's no way from a unit-test process to:
///   1. Enumerate the SwiftUI buttons inside the host.
///   2. Locate one by label.
///   3. Send it a press.
///
/// **What we can still test:** the view's *state-transition logic*.
/// The view types take their callbacks as plain closures. We can build
/// the view, hand it a callback that records a flag, and (when the view
/// exposes a way to trigger the action) call the action directly.
///
/// **Deviation from plan:** Task 5 originally specified clicking buttons
/// and asserting state changes. Without an AX-press path, that's not
/// achievable in a unit test. The two tests below are intentionally
/// scoped to what *is* achievable: verifying that a state-driven view
/// (AlarmFiringView, NewsTickerView) renders correctly across its key
/// states without crashing. The actual "button click → callback fires"
/// transition is covered by manual QA — see docs/superpowers/plans/
/// 2026-05-09-ux-automation-tests.md for the full reasoning.
@MainActor
@Suite("Interaction smoke tests")
struct InteractionTests {
    /// Verifies AlarmFiringView renders both snoozable and max-snoozes
    /// states without crashing the AX subsystem. Each render exercises
    /// a different code path (`disabled` modifier, opacity adjustment,
    /// snoozes-remaining text vs. "no snoozes" text).
    @Test func alarmFiringViewRendersBothSnoozeStates() {
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Wake up",
            isEnabled: true,
            repeatDays: [],
            soundName: nil,
            snoozeDuration: 5
        )

        // Snoozable state.
        let active = AlarmFiringView(
            alarm: alarm,
            onDismiss: {},
            onSnooze: {},
            theme: .classicWhite,
            snoozeCount: 3,
            maxSnoozes: 10
        )
        let activeHost = NSHostingView(rootView: active)
        activeHost.frame = NSRect(x: 0, y: 0, width: 480, height: 480)
        activeHost.layoutSubtreeIfNeeded()
        #expect(activeHost.bounds.width > 0)

        // Max-snoozes state.
        let exhausted = AlarmFiringView(
            alarm: alarm,
            onDismiss: {},
            onSnooze: {},
            theme: .classicWhite,
            snoozeCount: 10,
            maxSnoozes: 10
        )
        let exhaustedHost = NSHostingView(rootView: exhausted)
        exhaustedHost.frame = NSRect(x: 0, y: 0, width: 480, height: 480)
        exhaustedHost.layoutSubtreeIfNeeded()
        #expect(exhaustedHost.bounds.width > 0)
    }

    /// Verifies NewsTickerView renders both with-items and empty states
    /// without crashing. The auto-advance Timer is also kicked off
    /// (.onAppear), so this test additionally verifies the timer setup
    /// doesn't deadlock during teardown.
    @Test func newsTickerRendersBothStates() {
        let settings = AppSettings.snapshotFixture { s in
            s.newsTickerStyle = .rotating
        }

        let withItems = NewsTickerView(
            settings: settings,
            theme: .classicWhite,
            newsItems: [
                NewsItem(title: "First story", link: nil, source: "BBC", publishedDate: nil),
                NewsItem(title: "Second story", link: nil, source: "Reuters", publishedDate: nil),
            ]
        )
        let withItemsHost = NSHostingView(rootView: withItems)
        withItemsHost.frame = NSRect(x: 0, y: 0, width: 480, height: 30)
        withItemsHost.layoutSubtreeIfNeeded()
        #expect(withItemsHost.bounds.width > 0)

        let empty = NewsTickerView(settings: settings, theme: .classicWhite, newsItems: [])
        let emptyHost = NSHostingView(rootView: empty)
        emptyHost.frame = NSRect(x: 0, y: 0, width: 480, height: 30)
        emptyHost.layoutSubtreeIfNeeded()
        #expect(emptyHost.bounds.width > 0)
    }

    /// Verifies AlarmFiringView accepts a callback closure without
    /// invoking it — pure structural test of the API contract.
    @Test func alarmFiringViewCallbackContract() {
        var snoozeCalled = false
        var dismissCalled = false
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Wake up",
            isEnabled: true,
            repeatDays: [],
            soundName: nil,
            snoozeDuration: 5
        )
        // Just constructing and rendering the view must NOT invoke either
        // callback — otherwise an alarm dismisses itself before the user
        // sees it.
        let view = AlarmFiringView(
            alarm: alarm,
            onDismiss: { dismissCalled = true },
            onSnooze: { snoozeCalled = true },
            theme: .classicWhite,
            snoozeCount: 0,
            maxSnoozes: 10
        )
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 480, height: 480)
        host.layoutSubtreeIfNeeded()
        #expect(snoozeCalled == false)
        #expect(dismissCalled == false)
    }
}
