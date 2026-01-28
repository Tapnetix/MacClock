import Foundation
import Testing
@testable import MacClock

@Test func timeOfDayCalculation() {
    let calendar = Calendar.current
    let sunrise = calendar.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
    let sunset = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!

    let manager = BackgroundManager()

    // Test dawn (5:45 - before sunrise)
    let dawnTime = calendar.date(bySettingHour: 5, minute: 50, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: dawnTime, sunrise: sunrise, sunset: sunset) == .dawn)

    // Test day (12:00)
    let dayTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: dayTime, sunrise: sunrise, sunset: sunset) == .day)

    // Test dusk (17:45 - after sunset but within 1 hour)
    let duskTime = calendar.date(bySettingHour: 17, minute: 45, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: duskTime, sunrise: sunrise, sunset: sunset) == .dusk)

    // Test night (22:00)
    let nightTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: nightTime, sunrise: sunrise, sunset: sunset) == .night)
}
