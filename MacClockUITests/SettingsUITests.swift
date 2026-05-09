import XCTest

/// XCUITest cases for the Settings window.
///
/// The Settings window opens as a separate `Window("Settings", id: "settings")`
/// scene. It contains a row of tab buttons (General, Appearance, Window,
/// Location, World Clocks, Calendar, News, Extras) — each labelled via
/// `TabButton.accessibilityLabel(tab.title)`.
final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--test-mode"]
        app.launch()
        // Wait for main window before each test.
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10.0))
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    /// Helper: click the gear button and wait for the Settings window to
    /// appear. Returns the settings window XCUIElement.
    @discardableResult
    private func openSettings() -> XCUIElement {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5.0))
        settingsButton.click()

        // The settings window's identifier is "Settings" (matches the
        // SwiftUI Window's title). On older macOS or with some SwiftUI
        // versions it may instead be reachable by index, so fall back
        // to "any window other than the main one".
        let settingsWindow = app.windows["Settings"]
        if settingsWindow.waitForExistence(timeout: 3.0) {
            return settingsWindow
        }
        // Fallback: pick the most recently appeared window that has the
        // "General" tab button — that's the Settings window.
        let predicate = NSPredicate(format: "buttons['General'].exists == true")
        let anyWindow = app.windows.matching(predicate).firstMatch
        XCTAssertTrue(anyWindow.waitForExistence(timeout: 3.0), "Settings window did not appear")
        return anyWindow
    }

    func testSettingsButtonOpensSettingsWindow() {
        let window = openSettings()
        XCTAssertTrue(window.exists)

        // The General tab button should be present (it's the default).
        XCTAssertTrue(app.buttons["General"].waitForExistence(timeout: 2.0))
    }

    func testAllTabsArePresent() {
        openSettings()
        for tabName in ["General", "Appearance", "Window", "Location",
                        "World Clocks", "Calendar", "News", "Extras"] {
            XCTAssertTrue(
                app.buttons[tabName].waitForExistence(timeout: 2.0),
                "Settings tab '\(tabName)' not found"
            )
        }
    }

    func testTabNavigationSwitchesContent() {
        openSettings()

        // Default is General — "24-Hour Time" toggle should be visible.
        let twentyFourHourToggle = app.checkBoxes["24-Hour Time"]
        XCTAssertTrue(
            twentyFourHourToggle.waitForExistence(timeout: 2.0),
            "Expected '24-Hour Time' toggle on default General tab"
        )

        // Click Appearance tab — General-only content should disappear.
        app.buttons["Appearance"].click()

        // The 24-Hour Time toggle is General-tab only; after switching
        // it should no longer be hittable.
        let stillThereAfterSwitch = twentyFourHourToggle.waitForExistence(timeout: 0.5)
        XCTAssertFalse(
            stillThereAfterSwitch && twentyFourHourToggle.isHittable,
            "'24-Hour Time' toggle should not be hittable after switching to Appearance tab"
        )
    }

    func testToggle24HourCanBeClicked() {
        openSettings()

        let toggle = app.checkBoxes["24-Hour Time"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2.0))
        XCTAssertTrue(toggle.isHittable, "'24-Hour Time' toggle is not hittable")

        // Two clicks (toggle on, toggle off again) — restores initial
        // state and verifies the control accepts events without
        // crashing the app.
        toggle.click()
        toggle.click()

        // App should still be alive — the original main window still exists.
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    func testSettingsWindowCanBeClosed() {
        let window = openSettings()

        // Close the settings window using the standard close button.
        // Window's close button has accessibility identifier-equivalent
        // role; on macOS, app.windows["Settings"].buttons[XCUIIdentifierCloseWindow]
        // is the canonical handle.
        window.buttons[XCUIIdentifierCloseWindow].click()

        // The settings window should no longer exist (or no longer be hittable).
        let stillThere = window.waitForExistence(timeout: 1.0) && window.isHittable
        XCTAssertFalse(stillThere, "Settings window did not close")

        // Main window should still be there — closing settings shouldn't kill the app.
        XCTAssertTrue(app.windows.firstMatch.exists)
    }
}
