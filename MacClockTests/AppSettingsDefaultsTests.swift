import Testing
import Foundation
import AppKit
@testable import MacClock

/// Exhaustive default-value assertions covering every @UserDefault*-backed
/// property on `AppSettings`. Each property is asserted against a fresh,
/// empty UserDefaults suite — its default must match the pre-refactor `init`
/// behavior exactly. A wrong default silently resets users' settings on
/// upgrade, so this is the single most important safety net for the
/// AppSettings @UserDefault refactor (see plan
/// 2026-05-09-appsettings-userdefault-wrapper.md).
@Suite("AppSettings defaults match pre-refactor init")
struct AppSettingsDefaultsTests {

    /// Returns a fresh, empty UserDefaults suite scoped to this test.
    private static func freshDefaults(_ tag: String) -> (UserDefaults, String) {
        let suite = "test.macclock.defaults.\(tag).\(UUID().uuidString)"
        let store = UserDefaults(suiteName: suite)!
        store.removePersistentDomain(forName: suite)
        return (store, suite)
    }

    private static func makeSettings(_ tag: String) -> (AppSettings, () -> Void) {
        let (defaults, suite) = freshDefaults(tag)
        let settings = AppSettings(defaults: defaults)
        return (settings, { defaults.removePersistentDomain(forName: suite) })
    }

    // MARK: - Clock display

    @Test func use24HourDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("use24Hour"); defer { cleanup() }
        #expect(s.use24Hour == true)
    }

    @Test func showSecondsDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("showSeconds"); defer { cleanup() }
        #expect(s.showSeconds == true)
    }

    @Test func clockStyleDefaultsToDigital() {
        let (s, cleanup) = Self.makeSettings("clockStyle"); defer { cleanup() }
        #expect(s.clockStyle == .digital)
    }

    @Test func clockFontSizeDefaultsTo140() {
        let (s, cleanup) = Self.makeSettings("clockFontSize"); defer { cleanup() }
        #expect(s.clockFontSize == 140.0)
    }

    @Test func colorThemeDefaultsToClassicWhite() {
        let (s, cleanup) = Self.makeSettings("colorTheme"); defer { cleanup() }
        #expect(s.colorTheme == .classicWhite)
    }

    // MARK: - Window

    @Test func windowLevelDefaultsToNormal() {
        let (s, cleanup) = Self.makeSettings("windowLevel"); defer { cleanup() }
        #expect(s.windowLevel == .normal)
    }

    @Test func windowOpacityDefaultsTo1() {
        let (s, cleanup) = Self.makeSettings("windowOpacity"); defer { cleanup() }
        #expect(s.windowOpacity == 1.0)
    }

    @Test func backgroundModeDefaultsToNature() {
        let (s, cleanup) = Self.makeSettings("backgroundMode"); defer { cleanup() }
        #expect(s.backgroundMode == .nature)
    }

    @Test func backgroundCycleIntervalDefaultsTo600() {
        let (s, cleanup) = Self.makeSettings("backgroundCycleInterval"); defer { cleanup() }
        #expect(s.backgroundCycleInterval == 600.0)
    }

    @Test func customBackgroundPathDefaultsToNil() {
        let (s, cleanup) = Self.makeSettings("customBackgroundPath"); defer { cleanup() }
        #expect(s.customBackgroundPath == nil)
    }

    @Test func customBackgroundBookmarkDefaultsToNil() {
        let (s, cleanup) = Self.makeSettings("customBackgroundBookmark"); defer { cleanup() }
        #expect(s.customBackgroundBookmark == nil)
    }

    @Test func launchAtLoginDefaultsToFalse() {
        let (s, cleanup) = Self.makeSettings("launchAtLogin"); defer { cleanup() }
        #expect(s.launchAtLogin == false)
    }

    @Test func windowFrameDefaultsToZero() {
        let (s, cleanup) = Self.makeSettings("windowFrame"); defer { cleanup() }
        #expect(s.windowFrame == .zero)
    }

    // MARK: - Location

    @Test func useAutoLocationDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("useAutoLocation"); defer { cleanup() }
        #expect(s.useAutoLocation == true)
    }

    @Test func manualLocationNameDefaultsToEmpty() {
        let (s, cleanup) = Self.makeSettings("manualLocationName"); defer { cleanup() }
        #expect(s.manualLocationName == "")
    }

    @Test func manualLatitudeDefaultsToZero() {
        let (s, cleanup) = Self.makeSettings("manualLatitude"); defer { cleanup() }
        #expect(s.manualLatitude == 0.0)
    }

    @Test func manualLongitudeDefaultsToZero() {
        let (s, cleanup) = Self.makeSettings("manualLongitude"); defer { cleanup() }
        #expect(s.manualLongitude == 0.0)
    }

    // MARK: - Weather

    @Test func useCelsiusDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("useCelsius"); defer { cleanup() }
        #expect(s.useCelsius == true)
    }

    @Test func weatherDetailEnabledDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("weatherDetailEnabled"); defer { cleanup() }
        #expect(s.weatherDetailEnabled == true)
    }

    @Test func weatherShowCurrentDetailsDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("weatherShowCurrentDetails"); defer { cleanup() }
        #expect(s.weatherShowCurrentDetails == true)
    }

    @Test func weatherShowSunriseSunsetDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("weatherShowSunriseSunset"); defer { cleanup() }
        #expect(s.weatherShowSunriseSunset == true)
    }

    @Test func weatherShowHourlyDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("weatherShowHourly"); defer { cleanup() }
        #expect(s.weatherShowHourly == true)
    }

    @Test func weatherShowDailyDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("weatherShowDaily"); defer { cleanup() }
        #expect(s.weatherShowDaily == true)
    }

    // MARK: - Auto-dim

    @Test func autoDimEnabledDefaultsToFalse() {
        let (s, cleanup) = Self.makeSettings("autoDimEnabled"); defer { cleanup() }
        #expect(s.autoDimEnabled == false)
    }

    @Test func autoDimLevelDefaultsToHalf() {
        let (s, cleanup) = Self.makeSettings("autoDimLevel"); defer { cleanup() }
        #expect(s.autoDimLevel == 0.5)
    }

    @Test func autoDimModeDefaultsToSunriseSunset() {
        let (s, cleanup) = Self.makeSettings("autoDimMode"); defer { cleanup() }
        #expect(s.autoDimMode == .sunriseSunset)
    }

    @Test func dimStartHourDefaultsTo22() {
        let (s, cleanup) = Self.makeSettings("dimStartHour"); defer { cleanup() }
        #expect(s.dimStartHour == 22)
    }

    @Test func dimEndHourDefaultsTo7() {
        let (s, cleanup) = Self.makeSettings("dimEndHour"); defer { cleanup() }
        #expect(s.dimEndHour == 7)
    }

    @Test func nightThemeDefaultsToNil() {
        let (s, cleanup) = Self.makeSettings("nightTheme"); defer { cleanup() }
        #expect(s.nightTheme == nil)
    }

    @Test func autoThemeEnabledDefaultsToFalse() {
        let (s, cleanup) = Self.makeSettings("autoThemeEnabled"); defer { cleanup() }
        #expect(s.autoThemeEnabled == false)
    }

    @Test func dayThemeDefaultsToClassicWhite() {
        let (s, cleanup) = Self.makeSettings("dayTheme"); defer { cleanup() }
        #expect(s.dayTheme == .classicWhite)
    }

    @Test func nightThemeAutoDefaultsToWarmAmber() {
        let (s, cleanup) = Self.makeSettings("nightThemeAuto"); defer { cleanup() }
        #expect(s.nightThemeAuto == .warmAmber)
    }

    @Test func autoThemeModeDefaultsToSunriseSunset() {
        let (s, cleanup) = Self.makeSettings("autoThemeMode"); defer { cleanup() }
        #expect(s.autoThemeMode == .sunriseSunset)
    }

    // MARK: - World clocks

    @Test func worldClocksEnabledDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("worldClocksEnabled"); defer { cleanup() }
        #expect(s.worldClocksEnabled == true)
    }

    @Test func worldClocksPositionDefaultsToSide() {
        let (s, cleanup) = Self.makeSettings("worldClocksPosition"); defer { cleanup() }
        #expect(s.worldClocksPosition == .side)
    }

    @Test func worldClocksDefaultsToStarterSet() {
        let (s, cleanup) = Self.makeSettings("worldClocks"); defer { cleanup() }
        let names = s.worldClocks.map { $0.cityName }
        #expect(names == ["New York", "London", "Tokyo"])
    }

    @Test func showTimezoneAbbreviationDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("showTimezoneAbbreviation"); defer { cleanup() }
        #expect(s.showTimezoneAbbreviation == true)
    }

    @Test func showDayDifferenceDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("showDayDifference"); defer { cleanup() }
        #expect(s.showDayDifference == true)
    }

    // MARK: - News ticker

    @Test func newsTickerEnabledDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("newsTickerEnabled"); defer { cleanup() }
        #expect(s.newsTickerEnabled == true)
    }

    @Test func newsTickerStyleDefaultsToScrolling() {
        let (s, cleanup) = Self.makeSettings("newsTickerStyle"); defer { cleanup() }
        #expect(s.newsTickerStyle == .scrolling)
    }

    @Test func newsFeedsDefaultsToBuiltIn() {
        let (s, cleanup) = Self.makeSettings("newsFeeds"); defer { cleanup() }
        #expect(s.newsFeeds.count == NewsFeed.builtInFeeds.count)
        #expect(!s.newsFeeds.isEmpty)
    }

    @Test func newsRefreshIntervalDefaultsTo15() {
        let (s, cleanup) = Self.makeSettings("newsRefreshInterval"); defer { cleanup() }
        #expect(s.newsRefreshInterval == 15.0)
    }

    @Test func newsScrollSpeedDefaultsTo50() {
        let (s, cleanup) = Self.makeSettings("newsScrollSpeed"); defer { cleanup() }
        #expect(s.newsScrollSpeed == 50.0)
    }

    @Test func newsRotateIntervalDefaultsTo10() {
        let (s, cleanup) = Self.makeSettings("newsRotateInterval"); defer { cleanup() }
        #expect(s.newsRotateInterval == 10.0)
    }

    @Test func newsMaxAgeDaysDefaultsTo3() {
        let (s, cleanup) = Self.makeSettings("newsMaxAgeDays"); defer { cleanup() }
        #expect(s.newsMaxAgeDays == 3)
    }

    // MARK: - Calendar

    @Test func calendarEnabledDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("calendarEnabled"); defer { cleanup() }
        #expect(s.calendarEnabled == true)
    }

    @Test func calendarShowCountdownDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("calendarShowCountdown"); defer { cleanup() }
        #expect(s.calendarShowCountdown == true)
    }

    @Test func calendarShowAgendaDefaultsToTrue() {
        let (s, cleanup) = Self.makeSettings("calendarShowAgenda"); defer { cleanup() }
        #expect(s.calendarShowAgenda == true)
    }

    @Test func calendarAgendaPositionDefaultsToSide() {
        let (s, cleanup) = Self.makeSettings("calendarAgendaPosition"); defer { cleanup() }
        #expect(s.calendarAgendaPosition == .side)
    }

    @Test func selectedCalendarIDsDefaultsToEmpty() {
        let (s, cleanup) = Self.makeSettings("selectedCalendarIDs"); defer { cleanup() }
        #expect(s.selectedCalendarIDs.isEmpty)
    }

    @Test func iCalFeedsDefaultsToEmpty() {
        let (s, cleanup) = Self.makeSettings("iCalFeeds"); defer { cleanup() }
        #expect(s.iCalFeeds.isEmpty)
    }

    // MARK: - Alarms

    @Test func alarmsDefaultsToEmpty() {
        let (s, cleanup) = Self.makeSettings("alarms"); defer { cleanup() }
        #expect(s.alarms.isEmpty)
    }

    @Test func alarmOutputDeviceUIDDefaultsToEmpty() {
        let (s, cleanup) = Self.makeSettings("alarmOutputDeviceUID"); defer { cleanup() }
        #expect(s.alarmOutputDeviceUID == "")
    }
}
