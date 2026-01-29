import Testing
import Foundation
@testable import MacClock

@Suite("ICalService Tests")
struct ICalServiceTests {
    @Test("Parses simple VEVENT")
    func parsesSimpleEvent() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:test-event-1@example.com
        DTSTART:20260129T100000Z
        DTEND:20260129T110000Z
        SUMMARY:Team Meeting
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")

        #expect(events.count == 1)
        #expect(events[0].title == "Team Meeting")
        #expect(events[0].calendarTitle == "Test")
    }

    @Test("Parses all-day event")
    func parsesAllDayEvent() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:all-day-1@example.com
        DTSTART;VALUE=DATE:20260129
        DTEND;VALUE=DATE:20260130
        SUMMARY:Holiday
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#0000FF")

        #expect(events.count == 1)
        #expect(events[0].title == "Holiday")
        #expect(events[0].isAllDay == true)
    }

    @Test("Parses multiple events")
    func parsesMultipleEvents() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:event-1@example.com
        DTSTART:20260129T090000Z
        DTEND:20260129T100000Z
        SUMMARY:Morning Standup
        END:VEVENT
        BEGIN:VEVENT
        UID:event-2@example.com
        DTSTART:20260129T140000Z
        DTEND:20260129T150000Z
        SUMMARY:Afternoon Review
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Work", colorHex: "#00FF00")

        #expect(events.count == 2)
    }

    @Test("Handles missing SUMMARY gracefully")
    func handlesMissingSummary() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:no-title@example.com
        DTSTART:20260129T100000Z
        DTEND:20260129T110000Z
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")

        #expect(events.count == 1)
        #expect(events[0].title == "Untitled")
    }
}
