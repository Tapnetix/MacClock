import Testing
import Foundation
@testable import MacClock

@Suite("WorldClock Tests")
struct WorldClockTests {

    @Test("WorldClock stores city and timezone")
    func worldClockProperties() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "New York",
            timezoneIdentifier: "America/New_York"
        )
        #expect(clock.cityName == "New York")
        #expect(clock.timezoneIdentifier == "America/New_York")
    }

    @Test("WorldClock calculates current time")
    func currentTime() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "London",
            timezoneIdentifier: "Europe/London"
        )
        let time = clock.currentTimeString(use24Hour: false)
        #expect(!time.isEmpty)
    }

    @Test("WorldClock shows timezone abbreviation")
    func timezoneAbbreviation() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "Tokyo",
            timezoneIdentifier: "Asia/Tokyo"
        )
        // Abbreviation can be "JST" or "GMT+9" depending on system locale
        let abbrev = clock.timezoneAbbreviation
        #expect(abbrev == "JST" || abbrev == "GMT+9")
    }

    @Test("WorldClock calculates day difference")
    func dayDifference() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "Tokyo",
            timezoneIdentifier: "Asia/Tokyo"
        )
        // Day difference is relative to local time
        let diff = clock.dayDifferenceFromLocal
        #expect(diff >= -1 && diff <= 1)
    }
}
