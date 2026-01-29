import Foundation
import Testing
@testable import MacClock

@Test func shouldDimAtNightWithSunriseSunsetMode() {
    let calendar = Calendar.current
    // Sunrise at 6:45 AM, Sunset at 5:30 PM
    let sunrise = calendar.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
    let sunset = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!

    // 11 PM - should be dimmed (after sunset)
    let nightTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!

    let result = DimManager.shouldDim(
        at: nightTime,
        mode: .sunriseSunset,
        sunrise: sunrise,
        sunset: sunset,
        dimStartHour: 22,
        dimEndHour: 7
    )

    #expect(result == true)
}

@Test func shouldNotDimDuringDay() {
    let calendar = Calendar.current
    // Sunrise at 6:45 AM, Sunset at 5:30 PM
    let sunrise = calendar.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
    let sunset = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!

    // 12 PM - should not be dimmed (during day)
    let dayTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!

    let result = DimManager.shouldDim(
        at: dayTime,
        mode: .sunriseSunset,
        sunrise: sunrise,
        sunset: sunset,
        dimStartHour: 22,
        dimEndHour: 7
    )

    #expect(result == false)
}

@Test func shouldDimWithFixedSchedule() {
    let calendar = Calendar.current
    // 11:30 PM with fixed schedule (10 PM to 7 AM)
    let lateNight = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: Date())!

    let result = DimManager.shouldDim(
        at: lateNight,
        mode: .fixedSchedule,
        sunrise: nil,
        sunset: nil,
        dimStartHour: 22,
        dimEndHour: 7
    )

    #expect(result == true)
}

@Test func shouldNotDimOutsideFixedSchedule() {
    let calendar = Calendar.current
    // 2 PM - outside fixed schedule
    let afternoon = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!

    let result = DimManager.shouldDim(
        at: afternoon,
        mode: .fixedSchedule,
        sunrise: nil,
        sunset: nil,
        dimStartHour: 22,
        dimEndHour: 7
    )

    #expect(result == false)
}

@Test func shouldDimEarlyMorningWithFixedSchedule() {
    let calendar = Calendar.current
    // 5 AM - should be dimmed (before end hour 7)
    let earlyMorning = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: Date())!

    let result = DimManager.shouldDim(
        at: earlyMorning,
        mode: .fixedSchedule,
        sunrise: nil,
        sunset: nil,
        dimStartHour: 22,
        dimEndHour: 7
    )

    #expect(result == true)
}

@Test func shouldReturnFalseWhenSunriseSunsetNil() {
    let calendar = Calendar.current
    let nightTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!

    let result = DimManager.shouldDim(
        at: nightTime,
        mode: .sunriseSunset,
        sunrise: nil,
        sunset: nil,
        dimStartHour: 22,
        dimEndHour: 7
    )

    #expect(result == false)
}

@Test func updateSetsCorrectStateWhenAutoDimDisabled() {
    let dimManager = DimManager()
    let settings = AppSettings(defaults: UserDefaults(suiteName: "test.dimdisabled")!)
    settings.autoDimEnabled = false

    dimManager.update(settings: settings, sunrise: nil, sunset: nil)

    #expect(dimManager.isDimmed == false)
    #expect(dimManager.currentDimLevel == 1.0)
}
