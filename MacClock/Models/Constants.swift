import Foundation

/// Project-wide default constants. Values that have no UI surface to
/// configure them and would otherwise be hardcoded at the call site.
enum Constants {
    // MARK: - Default Location

    /// Latitude used when location services are unavailable and no
    /// manual location is configured.
    static let defaultLatitude: Double = 37.7749

    /// Longitude used when location services are unavailable and no
    /// manual location is configured.
    static let defaultLongitude: Double = -122.4194

    /// Display name corresponding to (defaultLatitude, defaultLongitude).
    static let defaultLocationName: String = "San Francisco"

    // MARK: - Default Sunrise / Sunset

    /// Hour (24h) used as the sunrise fallback when the weather service
    /// has not provided real sunrise data yet.
    static let defaultSunriseHour: Int = 6

    /// Hour (24h) used as the sunset fallback when the weather service
    /// has not provided real sunset data yet.
    static let defaultSunsetHour: Int = 18

    /// Minute used for both sunrise and sunset fallbacks.
    static let defaultSunriseMinute: Int = 30
    static let defaultSunsetMinute: Int = 30

    /// Computed fallback sunrise for today.
    static func defaultSunriseToday() -> Date {
        Calendar.current.date(
            bySettingHour: defaultSunriseHour,
            minute: defaultSunriseMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    /// Computed fallback sunset for today.
    static func defaultSunsetToday() -> Date {
        Calendar.current.date(
            bySettingHour: defaultSunsetHour,
            minute: defaultSunsetMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}
