import Foundation
import Testing
@testable import MacClock

@Test func defaultSettings() {
    let settings = AppSettings()
    #expect(settings.use24Hour == false)
    #expect(settings.showSeconds == true)
    #expect(settings.useCelsius == false)
    #expect(settings.windowLevel == .normal)
    #expect(settings.useAutoLocation == true)
    #expect(settings.clockFontSize == 96.0)
}

@Test func settingsPersistence() {
    let defaults = UserDefaults(suiteName: "test")!
    defaults.removePersistentDomain(forName: "test")

    let settings = AppSettings(defaults: defaults)
    settings.use24Hour = true
    settings.showSeconds = false

    let reloaded = AppSettings(defaults: defaults)
    #expect(reloaded.use24Hour == true)
    #expect(reloaded.showSeconds == false)
}

@Test("Theme defaults to classic white")
func themeDefault() {
    let defaults = UserDefaults(suiteName: "test-theme")!
    defaults.removePersistentDomain(forName: "test-theme")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.colorTheme == .classicWhite)
}

@Test("Theme persists to UserDefaults")
func themePersistence() {
    let defaults = UserDefaults(suiteName: "test-theme-persist")!
    defaults.removePersistentDomain(forName: "test-theme-persist")
    let settings = AppSettings(defaults: defaults)
    settings.colorTheme = .neonBlue
    #expect(defaults.string(forKey: "colorTheme") == "Neon Blue")
}

@Test("Auto-dim defaults to off")
func autoDimDefault() {
    let defaults = UserDefaults(suiteName: "test-autodim")!
    defaults.removePersistentDomain(forName: "test-autodim")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.autoDimEnabled == false)
    #expect(settings.autoDimLevel == 0.5)
    #expect(settings.autoDimMode == .sunriseSunset)
}

@Test("Clock style defaults to digital")
func clockStyleDefault() {
    let defaults = UserDefaults(suiteName: "test-clockstyle")!
    defaults.removePersistentDomain(forName: "test-clockstyle")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.clockStyle == .digital)
}

@Test("Auto theme defaults to disabled")
func autoThemeDefault() {
    let defaults = UserDefaults(suiteName: "test-autotheme")!
    defaults.removePersistentDomain(forName: "test-autotheme")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.autoThemeEnabled == false)
    #expect(settings.dayTheme == .classicWhite)
    #expect(settings.nightThemeAuto == .warmAmber)
}

@Test("World clocks default to empty")
func worldClocksDefault() {
    let defaults = UserDefaults(suiteName: "test-worldclocks")!
    defaults.removePersistentDomain(forName: "test-worldclocks")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.worldClocks.isEmpty)
    #expect(settings.worldClocksEnabled == false)
    #expect(settings.worldClocksPosition == .bottom)
}
