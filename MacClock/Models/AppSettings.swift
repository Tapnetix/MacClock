import Foundation
import SwiftUI
import AppKit

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

@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var use24Hour: Bool {
        didSet { defaults.set(use24Hour, forKey: "use24Hour") }
    }

    var showSeconds: Bool {
        didSet { defaults.set(showSeconds, forKey: "showSeconds") }
    }

    var useCelsius: Bool {
        didSet { defaults.set(useCelsius, forKey: "useCelsius") }
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
        self.windowLevel = WindowLevel(rawValue: defaults.string(forKey: "windowLevel") ?? "") ?? .normal
        self.useAutoLocation = defaults.object(forKey: "useAutoLocation") as? Bool ?? true
        self.manualLocationName = defaults.string(forKey: "manualLocationName") ?? ""
        self.manualLatitude = defaults.double(forKey: "manualLatitude")
        self.manualLongitude = defaults.double(forKey: "manualLongitude")
        self.customBackgroundPath = defaults.string(forKey: "customBackgroundPath")
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
        if let data = defaults.data(forKey: "worldClocks"),
           let clocks = try? JSONDecoder().decode([WorldClock].self, from: data) {
            self.worldClocks = clocks
        } else {
            self.worldClocks = []
        }
        self.showTimezoneAbbreviation = defaults.object(forKey: "showTimezoneAbbreviation") as? Bool ?? true
        self.showDayDifference = defaults.object(forKey: "showDayDifference") as? Bool ?? true
    }
}
