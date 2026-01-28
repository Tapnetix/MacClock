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
