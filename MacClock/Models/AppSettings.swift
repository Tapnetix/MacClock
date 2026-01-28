import Foundation
import SwiftUI
import AppKit

enum WindowLevel: String, CaseIterable {
    case normal = "Normal"
    case floating = "Floating"
    case desktop = "Desktop"
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
    }
}
