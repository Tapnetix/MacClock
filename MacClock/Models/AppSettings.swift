import Foundation
import SwiftUI
import AppKit
import OSLog
import Observation

enum WindowLevel: String, CaseIterable {
    case normal = "Normal"
    case floating = "Floating"
    case desktop = "Desktop"
}

enum BackgroundMode: String, CaseIterable {
    case timeOfDay = "Time of Day"
    case nature = "Nature Photos"
    case custom = "Custom"
}

enum AutoDimMode: String, CaseIterable {
    case sunriseSunset = "Sunrise/Sunset"
    case fixedSchedule = "Fixed Schedule"
    case macOSAppearance = "Follow macOS"
}

enum ClockStyle: String, CaseIterable {
    case digital = "Digital"
    case analog = "Analog"
    case flip = "Flip Clock"
}

enum WorldClocksPosition: String, CaseIterable {
    case bottom = "Bottom Bar"
    case side = "Side Panel"
}

enum NewsTickerStyle: String, CaseIterable {
    case scrolling = "Scrolling"
    case rotating = "Rotating"
}

@Observable
final class AppSettings: UserDefaultsBacked {
    // MARK: - UserDefaultsBacked conformance

    let userDefaultsStore: UserDefaults

    @ObservationIgnored
    var observationRegistrar: ObservationRegistrar { _$observationRegistrar }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MacClock", category: "AppSettings")

    // MARK: - Clock display

    @ObservationIgnored @UserDefault(key: "use24Hour")
    var use24Hour: Bool = false

    @ObservationIgnored @UserDefault(key: "showSeconds")
    var showSeconds: Bool = true

    @ObservationIgnored @UserDefaultRaw(key: "clockStyle")
    var clockStyle: ClockStyle = .digital

    @ObservationIgnored @UserDefault(key: "clockFontSize")
    var clockFontSize: Double = 96.0

    @ObservationIgnored @UserDefaultRaw(key: "colorTheme")
    var colorTheme: ColorTheme = .classicWhite

    // MARK: - Window

    @ObservationIgnored @UserDefaultRaw(key: "windowLevel")
    var windowLevel: WindowLevel = .normal

    @ObservationIgnored @UserDefault(key: "windowOpacity")
    var windowOpacity: Double = 1.0

    @ObservationIgnored @UserDefaultRaw(key: "backgroundMode")
    var backgroundMode: BackgroundMode = .timeOfDay

    @ObservationIgnored @UserDefault(key: "backgroundCycleInterval")
    var backgroundCycleInterval: Double = 60.0

    @ObservationIgnored @UserDefaultOptional(key: "customBackgroundPath")
    var customBackgroundPath: String? = nil

    @ObservationIgnored @UserDefaultOptional(key: "customBackgroundBookmark")
    var customBackgroundBookmark: Data? = nil

    @ObservationIgnored @UserDefault(key: "launchAtLogin")
    var launchAtLogin: Bool = false

    // MARK: - Location

    @ObservationIgnored @UserDefault(key: "useAutoLocation")
    var useAutoLocation: Bool = true

    @ObservationIgnored @UserDefault(key: "manualLocationName")
    var manualLocationName: String = ""

    @ObservationIgnored @UserDefault(key: "manualLatitude")
    var manualLatitude: Double = 0.0

    @ObservationIgnored @UserDefault(key: "manualLongitude")
    var manualLongitude: Double = 0.0

    // MARK: - Weather

    @ObservationIgnored @UserDefault(key: "useCelsius")
    var useCelsius: Bool = false

    @ObservationIgnored @UserDefault(key: "weatherDetailEnabled")
    var weatherDetailEnabled: Bool = true

    @ObservationIgnored @UserDefault(key: "weatherShowCurrentDetails")
    var weatherShowCurrentDetails: Bool = true

    @ObservationIgnored @UserDefault(key: "weatherShowSunriseSunset")
    var weatherShowSunriseSunset: Bool = true

    @ObservationIgnored @UserDefault(key: "weatherShowHourly")
    var weatherShowHourly: Bool = true

    @ObservationIgnored @UserDefault(key: "weatherShowDaily")
    var weatherShowDaily: Bool = true

    // MARK: - Auto-dim and theme

    @ObservationIgnored @UserDefault(key: "autoDimEnabled")
    var autoDimEnabled: Bool = false

    @ObservationIgnored @UserDefault(key: "autoDimLevel")
    var autoDimLevel: Double = 0.5

    @ObservationIgnored @UserDefaultRaw(key: "autoDimMode")
    var autoDimMode: AutoDimMode = .sunriseSunset

    @ObservationIgnored @UserDefault(key: "dimStartHour")
    var dimStartHour: Int = 22

    @ObservationIgnored @UserDefault(key: "dimEndHour")
    var dimEndHour: Int = 7

    @ObservationIgnored @UserDefaultRawOptional(key: "nightTheme")
    var nightTheme: ColorTheme? = nil

    @ObservationIgnored @UserDefault(key: "autoThemeEnabled")
    var autoThemeEnabled: Bool = false

    @ObservationIgnored @UserDefaultRaw(key: "dayTheme")
    var dayTheme: ColorTheme = .classicWhite

    @ObservationIgnored @UserDefaultRaw(key: "nightThemeAuto")
    var nightThemeAuto: ColorTheme = .warmAmber

    @ObservationIgnored @UserDefaultRaw(key: "autoThemeMode")
    var autoThemeMode: AutoDimMode = .sunriseSunset

    // MARK: - World clocks

    @ObservationIgnored @UserDefault(key: "worldClocksEnabled")
    var worldClocksEnabled: Bool = false

    @ObservationIgnored @UserDefaultRaw(key: "worldClocksPosition")
    var worldClocksPosition: WorldClocksPosition = .bottom

    @ObservationIgnored @UserDefaultCodable(key: "worldClocks")
    var worldClocks: [WorldClock] = []

    @ObservationIgnored @UserDefault(key: "showTimezoneAbbreviation")
    var showTimezoneAbbreviation: Bool = true

    @ObservationIgnored @UserDefault(key: "showDayDifference")
    var showDayDifference: Bool = true

    // MARK: - News ticker

    @ObservationIgnored @UserDefault(key: "newsTickerEnabled")
    var newsTickerEnabled: Bool = false

    @ObservationIgnored @UserDefaultRaw(key: "newsTickerStyle")
    var newsTickerStyle: NewsTickerStyle = .scrolling

    @ObservationIgnored @UserDefaultCodable(key: "newsFeeds")
    var newsFeeds: [NewsFeed] = NewsFeed.builtInFeeds

    @ObservationIgnored @UserDefault(key: "newsRefreshInterval")
    var newsRefreshInterval: Double = 15.0

    @ObservationIgnored @UserDefault(key: "newsScrollSpeed")
    var newsScrollSpeed: Double = 50.0

    @ObservationIgnored @UserDefault(key: "newsRotateInterval")
    var newsRotateInterval: Double = 10.0

    @ObservationIgnored @UserDefault(key: "newsMaxAgeDays")
    var newsMaxAgeDays: Int = 3

    // MARK: - Calendar and alarms

    @ObservationIgnored @UserDefault(key: "calendarEnabled")
    var calendarEnabled: Bool = false

    @ObservationIgnored @UserDefault(key: "calendarShowCountdown")
    var calendarShowCountdown: Bool = true

    @ObservationIgnored @UserDefault(key: "calendarShowAgenda")
    var calendarShowAgenda: Bool = false

    @ObservationIgnored @UserDefaultRaw(key: "calendarAgendaPosition")
    var calendarAgendaPosition: WorldClocksPosition = .side

    @ObservationIgnored @UserDefault(key: "selectedCalendarIDs")
    var selectedCalendarIDs: [String] = []

    @ObservationIgnored @UserDefaultCodable(key: "iCalFeeds")
    var iCalFeeds: [ICalFeed] = []

    @ObservationIgnored @UserDefaultCodable(key: "alarms")
    var alarms: [Alarm] = []

    @ObservationIgnored @UserDefault(key: "alarmOutputDeviceUID")
    var alarmOutputDeviceUID: String = ""

    // MARK: - Window frame (4-scalar; not migrated to @UserDefault)

    /// Stored as four scalar keys (windowX, windowY, windowWidth, windowHeight)
    /// for historical reasons. Not migrated to @UserDefault because the wrapper
    /// assumes one key per property; migrating would require a schema migration
    /// (out of scope — see plans/2026-05-09-appsettings-userdefault-wrapper.md).
    var windowFrame: NSRect {
        get {
            let x = userDefaultsStore.double(forKey: "windowX")
            let y = userDefaultsStore.double(forKey: "windowY")
            let w = userDefaultsStore.double(forKey: "windowWidth")
            let h = userDefaultsStore.double(forKey: "windowHeight")
            if w > 0 && h > 0 {
                return NSRect(x: x, y: y, width: w, height: h)
            }
            return .zero
        }
        set {
            userDefaultsStore.set(newValue.origin.x, forKey: "windowX")
            userDefaultsStore.set(newValue.origin.y, forKey: "windowY")
            userDefaultsStore.set(newValue.width, forKey: "windowWidth")
            userDefaultsStore.set(newValue.height, forKey: "windowHeight")
        }
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.userDefaultsStore = defaults

        // Migration: build a bookmark from a legacy raw path so existing
        // custom-background users don't lose their selection. This runs
        // once; subsequent launches read the persisted bookmark directly.
        if customBackgroundBookmark == nil,
           let path = customBackgroundPath, !path.isEmpty {
            let url = URL(fileURLWithPath: path)
            if let data = try? url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                self.customBackgroundBookmark = data
            }
        }
    }
}
