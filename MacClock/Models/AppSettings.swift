import Foundation
import SwiftUI
import AppKit
import OSLog

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
final class AppSettings {
    private let defaults: UserDefaults
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MacClock", category: "AppSettings")

    var use24Hour: Bool {
        didSet { defaults.set(use24Hour, forKey: "use24Hour") }
    }

    var showSeconds: Bool {
        didSet { defaults.set(showSeconds, forKey: "showSeconds") }
    }

    var useCelsius: Bool {
        didSet { defaults.set(useCelsius, forKey: "useCelsius") }
    }

    var weatherDetailEnabled: Bool {
        didSet { defaults.set(weatherDetailEnabled, forKey: "weatherDetailEnabled") }
    }

    var weatherShowCurrentDetails: Bool {
        didSet { defaults.set(weatherShowCurrentDetails, forKey: "weatherShowCurrentDetails") }
    }

    var weatherShowSunriseSunset: Bool {
        didSet { defaults.set(weatherShowSunriseSunset, forKey: "weatherShowSunriseSunset") }
    }

    var weatherShowHourly: Bool {
        didSet { defaults.set(weatherShowHourly, forKey: "weatherShowHourly") }
    }

    var weatherShowDaily: Bool {
        didSet { defaults.set(weatherShowDaily, forKey: "weatherShowDaily") }
    }

    var windowLevel: WindowLevel {
        didSet { defaults.set(windowLevel.rawValue, forKey: "windowLevel") }
    }

    var useAutoLocation: Bool {
        didSet { defaults.set(useAutoLocation, forKey: "useAutoLocation") }
    }

    var manualLocationName: String {
        didSet { defaults.set(manualLocationName, forKey: "manualLocationName") }
    }

    var manualLatitude: Double {
        didSet { defaults.set(manualLatitude, forKey: "manualLatitude") }
    }

    var manualLongitude: Double {
        didSet { defaults.set(manualLongitude, forKey: "manualLongitude") }
    }

    var customBackgroundPath: String? {
        didSet { defaults.set(customBackgroundPath, forKey: "customBackgroundPath") }
    }

    var customBackgroundBookmark: Data? {
        didSet {
            if let data = customBackgroundBookmark {
                defaults.set(data, forKey: "customBackgroundBookmark")
            } else {
                defaults.removeObject(forKey: "customBackgroundBookmark")
            }
        }
    }

    var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    var clockFontSize: Double {
        didSet { defaults.set(clockFontSize, forKey: "clockFontSize") }
    }

    var backgroundMode: BackgroundMode {
        didSet { defaults.set(backgroundMode.rawValue, forKey: "backgroundMode") }
    }

    var backgroundCycleInterval: Double {
        didSet { defaults.set(backgroundCycleInterval, forKey: "backgroundCycleInterval") }
    }

    var windowOpacity: Double {
        didSet { defaults.set(windowOpacity, forKey: "windowOpacity") }
    }

    var colorTheme: ColorTheme {
        didSet { defaults.set(colorTheme.rawValue, forKey: "colorTheme") }
    }

    var autoDimEnabled: Bool {
        didSet { defaults.set(autoDimEnabled, forKey: "autoDimEnabled") }
    }

    var autoDimLevel: Double {
        didSet { defaults.set(autoDimLevel, forKey: "autoDimLevel") }
    }

    var autoDimMode: AutoDimMode {
        didSet { defaults.set(autoDimMode.rawValue, forKey: "autoDimMode") }
    }

    var dimStartHour: Int {
        didSet { defaults.set(dimStartHour, forKey: "dimStartHour") }
    }

    var dimEndHour: Int {
        didSet { defaults.set(dimEndHour, forKey: "dimEndHour") }
    }

    var nightTheme: ColorTheme? {
        didSet {
            if let theme = nightTheme {
                defaults.set(theme.rawValue, forKey: "nightTheme")
            } else {
                defaults.removeObject(forKey: "nightTheme")
            }
        }
    }

    var clockStyle: ClockStyle {
        didSet { defaults.set(clockStyle.rawValue, forKey: "clockStyle") }
    }

    var autoThemeEnabled: Bool {
        didSet { defaults.set(autoThemeEnabled, forKey: "autoThemeEnabled") }
    }

    var dayTheme: ColorTheme {
        didSet { defaults.set(dayTheme.rawValue, forKey: "dayTheme") }
    }

    var nightThemeAuto: ColorTheme {
        didSet { defaults.set(nightThemeAuto.rawValue, forKey: "nightThemeAuto") }
    }

    var autoThemeMode: AutoDimMode {
        didSet { defaults.set(autoThemeMode.rawValue, forKey: "autoThemeMode") }
    }

    var worldClocksEnabled: Bool {
        didSet { defaults.set(worldClocksEnabled, forKey: "worldClocksEnabled") }
    }

    var worldClocksPosition: WorldClocksPosition {
        didSet { defaults.set(worldClocksPosition.rawValue, forKey: "worldClocksPosition") }
    }

    var worldClocks: [WorldClock] {
        didSet {
            if let data = try? JSONEncoder().encode(worldClocks) {
                defaults.set(data, forKey: "worldClocks")
            }
        }
    }

    var showTimezoneAbbreviation: Bool {
        didSet { defaults.set(showTimezoneAbbreviation, forKey: "showTimezoneAbbreviation") }
    }

    var showDayDifference: Bool {
        didSet { defaults.set(showDayDifference, forKey: "showDayDifference") }
    }

    var newsTickerEnabled: Bool {
        didSet { defaults.set(newsTickerEnabled, forKey: "newsTickerEnabled") }
    }

    var newsTickerStyle: NewsTickerStyle {
        didSet { defaults.set(newsTickerStyle.rawValue, forKey: "newsTickerStyle") }
    }

    var newsFeeds: [NewsFeed] {
        didSet {
            if let data = try? JSONEncoder().encode(newsFeeds) {
                defaults.set(data, forKey: "newsFeeds")
            }
        }
    }

    var newsRefreshInterval: Double {
        didSet { defaults.set(newsRefreshInterval, forKey: "newsRefreshInterval") }
    }

    var newsScrollSpeed: Double {
        didSet { defaults.set(newsScrollSpeed, forKey: "newsScrollSpeed") }
    }

    var newsRotateInterval: Double {
        didSet { defaults.set(newsRotateInterval, forKey: "newsRotateInterval") }
    }

    var newsMaxAgeDays: Int {
        didSet { defaults.set(newsMaxAgeDays, forKey: "newsMaxAgeDays") }
    }

    var calendarEnabled: Bool {
        didSet { defaults.set(calendarEnabled, forKey: "calendarEnabled") }
    }

    var calendarShowCountdown: Bool {
        didSet { defaults.set(calendarShowCountdown, forKey: "calendarShowCountdown") }
    }

    var calendarShowAgenda: Bool {
        didSet { defaults.set(calendarShowAgenda, forKey: "calendarShowAgenda") }
    }

    var calendarAgendaPosition: WorldClocksPosition {
        didSet { defaults.set(calendarAgendaPosition.rawValue, forKey: "calendarAgendaPosition") }
    }

    var selectedCalendarIDs: [String] {
        didSet { defaults.set(selectedCalendarIDs, forKey: "selectedCalendarIDs") }
    }

    var iCalFeeds: [ICalFeed] {
        didSet {
            if let data = try? JSONEncoder().encode(iCalFeeds) {
                defaults.set(data, forKey: "iCalFeeds")
            }
        }
    }

    var alarms: [Alarm] {
        didSet {
            if let data = try? JSONEncoder().encode(alarms) {
                defaults.set(data, forKey: "alarms")
            }
        }
    }

    var alarmOutputDeviceUID: String {
        didSet { defaults.set(alarmOutputDeviceUID, forKey: "alarmOutputDeviceUID") }
    }

    var windowFrame: NSRect {
        get {
            let x = defaults.double(forKey: "windowX")
            let y = defaults.double(forKey: "windowY")
            let w = defaults.double(forKey: "windowWidth")
            let h = defaults.double(forKey: "windowHeight")
            if w > 0 && h > 0 {
                return NSRect(x: x, y: y, width: w, height: h)
            }
            return .zero
        }
        set {
            defaults.set(newValue.origin.x, forKey: "windowX")
            defaults.set(newValue.origin.y, forKey: "windowY")
            defaults.set(newValue.width, forKey: "windowWidth")
            defaults.set(newValue.height, forKey: "windowHeight")
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.use24Hour = defaults.bool(forKey: "use24Hour")
        self.showSeconds = defaults.object(forKey: "showSeconds") as? Bool ?? true
        self.useCelsius = defaults.bool(forKey: "useCelsius")
        self.weatherDetailEnabled = defaults.object(forKey: "weatherDetailEnabled") as? Bool ?? true
        self.weatherShowCurrentDetails = defaults.object(forKey: "weatherShowCurrentDetails") as? Bool ?? true
        self.weatherShowSunriseSunset = defaults.object(forKey: "weatherShowSunriseSunset") as? Bool ?? true
        self.weatherShowHourly = defaults.object(forKey: "weatherShowHourly") as? Bool ?? true
        self.weatherShowDaily = defaults.object(forKey: "weatherShowDaily") as? Bool ?? true
        self.windowLevel = WindowLevel(rawValue: defaults.string(forKey: "windowLevel") ?? "") ?? .normal
        self.useAutoLocation = defaults.object(forKey: "useAutoLocation") as? Bool ?? true
        self.manualLocationName = defaults.string(forKey: "manualLocationName") ?? ""
        self.manualLatitude = defaults.double(forKey: "manualLatitude")
        self.manualLongitude = defaults.double(forKey: "manualLongitude")
        self.customBackgroundPath = defaults.string(forKey: "customBackgroundPath")
        self.customBackgroundBookmark = defaults.data(forKey: "customBackgroundBookmark")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.clockFontSize = defaults.object(forKey: "clockFontSize") as? Double ?? 96.0
        self.backgroundMode = BackgroundMode(rawValue: defaults.string(forKey: "backgroundMode") ?? "") ?? .timeOfDay
        self.backgroundCycleInterval = defaults.object(forKey: "backgroundCycleInterval") as? Double ?? 60.0
        self.windowOpacity = defaults.object(forKey: "windowOpacity") as? Double ?? 1.0
        self.colorTheme = ColorTheme(rawValue: defaults.string(forKey: "colorTheme") ?? "") ?? .classicWhite
        self.autoDimEnabled = defaults.bool(forKey: "autoDimEnabled")
        self.autoDimLevel = defaults.object(forKey: "autoDimLevel") as? Double ?? 0.5
        self.autoDimMode = AutoDimMode(rawValue: defaults.string(forKey: "autoDimMode") ?? "") ?? .sunriseSunset
        self.dimStartHour = defaults.object(forKey: "dimStartHour") as? Int ?? 22
        self.dimEndHour = defaults.object(forKey: "dimEndHour") as? Int ?? 7
        if let nightThemeRaw = defaults.string(forKey: "nightTheme") {
            self.nightTheme = ColorTheme(rawValue: nightThemeRaw)
        } else {
            self.nightTheme = nil
        }
        self.clockStyle = ClockStyle(rawValue: defaults.string(forKey: "clockStyle") ?? "") ?? .digital
        self.autoThemeEnabled = defaults.bool(forKey: "autoThemeEnabled")
        self.dayTheme = ColorTheme(rawValue: defaults.string(forKey: "dayTheme") ?? "") ?? .classicWhite
        self.nightThemeAuto = ColorTheme(rawValue: defaults.string(forKey: "nightThemeAuto") ?? "") ?? .warmAmber
        self.autoThemeMode = AutoDimMode(rawValue: defaults.string(forKey: "autoThemeMode") ?? "") ?? .sunriseSunset
        self.worldClocksEnabled = defaults.bool(forKey: "worldClocksEnabled")
        self.worldClocksPosition = WorldClocksPosition(rawValue: defaults.string(forKey: "worldClocksPosition") ?? "") ?? .bottom
        self.worldClocks = Self.decodeOrDefault([WorldClock].self, key: "worldClocks", defaults: defaults, fallback: [])
        self.showTimezoneAbbreviation = defaults.object(forKey: "showTimezoneAbbreviation") as? Bool ?? true
        self.showDayDifference = defaults.object(forKey: "showDayDifference") as? Bool ?? true
        self.newsTickerEnabled = defaults.bool(forKey: "newsTickerEnabled")
        self.newsTickerStyle = NewsTickerStyle(rawValue: defaults.string(forKey: "newsTickerStyle") ?? "") ?? .scrolling
        self.newsFeeds = Self.decodeOrDefault([NewsFeed].self, key: "newsFeeds", defaults: defaults, fallback: NewsFeed.builtInFeeds)
        self.newsRefreshInterval = defaults.object(forKey: "newsRefreshInterval") as? Double ?? 15.0
        self.newsScrollSpeed = defaults.object(forKey: "newsScrollSpeed") as? Double ?? 50.0
        self.newsRotateInterval = defaults.object(forKey: "newsRotateInterval") as? Double ?? 10.0
        self.newsMaxAgeDays = defaults.object(forKey: "newsMaxAgeDays") as? Int ?? 3
        self.calendarEnabled = defaults.bool(forKey: "calendarEnabled")
        self.calendarShowCountdown = defaults.object(forKey: "calendarShowCountdown") as? Bool ?? true
        self.calendarShowAgenda = defaults.bool(forKey: "calendarShowAgenda")
        self.calendarAgendaPosition = WorldClocksPosition(rawValue: defaults.string(forKey: "calendarAgendaPosition") ?? "") ?? .side
        self.selectedCalendarIDs = defaults.stringArray(forKey: "selectedCalendarIDs") ?? []
        self.iCalFeeds = Self.decodeOrDefault([ICalFeed].self, key: "iCalFeeds", defaults: defaults, fallback: [])
        self.alarms = Self.decodeOrDefault([Alarm].self, key: "alarms", defaults: defaults, fallback: [])
        self.alarmOutputDeviceUID = defaults.string(forKey: "alarmOutputDeviceUID") ?? ""

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
                defaults.set(data, forKey: "customBackgroundBookmark")
            }
        }
    }

    /// Decodes a Codable value from UserDefaults. On decode failure, logs
    /// the error and returns `fallback`. A logged decode failure usually
    /// means a missed schema migration — see `SchemaMigration.swift`.
    private static func decodeOrDefault<T: Decodable>(
        _ type: T.Type,
        key: String,
        defaults: UserDefaults,
        fallback: T
    ) -> T {
        guard let data = defaults.data(forKey: key) else { return fallback }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.error("AppSettings decode failed for \(key, privacy: .public): \(String(describing: error), privacy: .public). Falling back to default — likely a missed schema migration.")
            return fallback
        }
    }
}
