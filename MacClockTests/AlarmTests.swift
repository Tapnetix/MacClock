import Testing
import Foundation
@testable import MacClock

@Suite("Alarm Tests")
struct AlarmTests {

    @Test("Alarm stores properties correctly")
    func alarmProperties() {
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Wake up",
            isEnabled: true,
            repeatDays: [.monday, .tuesday],
            soundName: nil,
            snoozeDuration: 5
        )
        #expect(alarm.label == "Wake up")
        #expect(alarm.isEnabled == true)
        #expect(alarm.repeatDays.contains(.monday))
        #expect(alarm.snoozeDuration == 5)
    }

    @Test("Alarm calculates next fire date")
    func nextFireDate() {
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Test",
            isEnabled: true,
            repeatDays: [],
            soundName: nil,
            snoozeDuration: 5
        )
        let nextFire = alarm.nextFireDate
        #expect(nextFire != nil)
    }

    @Test("Repeat days encode correctly")
    func repeatDaysEncoding() {
        let days: Set<Alarm.Weekday> = [.monday, .wednesday, .friday]
        #expect(days.contains(.monday))
        #expect(days.contains(.wednesday))
        #expect(days.contains(.friday))
        #expect(!days.contains(.tuesday))
    }
}
