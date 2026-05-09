import XCTest

/// Smoke-level UI tests: the app launches, the main window appears,
/// the top-right control buttons (Settings, Alarms) are present and
/// reachable.
///
/// These tests rely on the accessibility labels added in CR-12 — if
/// the labels "Settings" or "Alarms" are renamed or removed, these
/// tests will fail. That is the correct behaviour: VoiceOver and
/// XCUITest both depend on those labels, so a regression here is a
/// real accessibility regression.
final class MacClockSmokeTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // --test-mode makes the production app store all UserDefaults
        // state in a throwaway suite and clear it on launch, so tests
        // never interfere with the developer's saved settings.
        app.launchArguments = ["--test-mode"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testAppLaunchesAndShowsMainWindow() {
        let window = app.windows.firstMatch
        XCTAssertTrue(
            window.waitForExistence(timeout: 10.0),
            "Main window did not appear within 10s of launch"
        )
    }

    func testSettingsAndAlarmsButtonsExist() {
        // Wait for the window to be up before querying for buttons.
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10.0))

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 5.0),
            "Settings button (accessibilityLabel: Settings) not present"
        )

        let alarmsButton = app.buttons["Alarms"]
        XCTAssertTrue(
            alarmsButton.exists,
            "Alarms button (accessibilityLabel: Alarms) not present"
        )
    }

    func testAlarmsButtonOpensAlarmPanel() {
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10.0))

        let alarmsButton = app.buttons["Alarms"]
        XCTAssertTrue(alarmsButton.waitForExistence(timeout: 5.0))

        let windowCountBefore = app.windows.count
        alarmsButton.click()

        // Opening the alarm sheet either spawns a new window or, more
        // commonly for SwiftUI sheets, attaches a sheet to the existing
        // window. Either way we expect the *count* of either windows
        // or sheets to grow, or at minimum a button labeled "Add" or
        // similar in the alarm panel to appear.
        let panelAppeared = app.sheets.firstMatch.waitForExistence(timeout: 3.0)
            || app.windows.count > windowCountBefore
        XCTAssertTrue(
            panelAppeared,
            "Alarm panel did not appear after clicking the Alarms button"
        )
    }
}
