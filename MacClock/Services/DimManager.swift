import Foundation
import AppKit

@Observable
final class DimManager {
    private(set) var isDimmed: Bool = false
    private(set) var currentDimLevel: Double = 1.0
    private(set) var effectiveTheme: ColorTheme = .classicWhite

    static func shouldDim(
        at date: Date,
        mode: AutoDimMode,
        sunrise: Date?,
        sunset: Date?,
        dimStartHour: Int,
        dimEndHour: Int
    ) -> Bool {
        switch mode {
        case .sunriseSunset:
            guard let sunrise = sunrise, let sunset = sunset else {
                return false
            }
            // Dim if before sunrise OR after sunset
            return date < sunrise || date > sunset

        case .fixedSchedule:
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            // Handles overnight: dim if hour >= start OR hour < end
            // e.g., start=22, end=7 means dim from 10 PM to 7 AM
            if dimStartHour > dimEndHour {
                // Overnight schedule
                return hour >= dimStartHour || hour < dimEndHour
            } else {
                // Same-day schedule (unlikely but handled)
                return hour >= dimStartHour && hour < dimEndHour
            }

        case .macOSAppearance:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }

    func update(settings: AppSettings, sunrise: Date?, sunset: Date?) {
        // Handle auto-dim
        if !settings.autoDimEnabled {
            isDimmed = false
            currentDimLevel = 1.0
        } else {
            let shouldDimNow = Self.shouldDim(
                at: Date(),
                mode: settings.autoDimMode,
                sunrise: sunrise,
                sunset: sunset,
                dimStartHour: settings.dimStartHour,
                dimEndHour: settings.dimEndHour
            )
            isDimmed = shouldDimNow
            currentDimLevel = shouldDimNow ? settings.autoDimLevel : 1.0
        }

        // Handle auto-theme
        if settings.autoThemeEnabled {
            let isNight = Self.shouldDim(
                at: Date(),
                mode: settings.autoThemeMode,
                sunrise: sunrise,
                sunset: sunset,
                dimStartHour: settings.dimStartHour,
                dimEndHour: settings.dimEndHour
            )
            effectiveTheme = isNight ? settings.nightThemeAuto : settings.dayTheme
        } else {
            effectiveTheme = settings.colorTheme
        }
    }
}
