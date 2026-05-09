import Testing
import Foundation
import CoreGraphics
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

    @Test("Cache round-trip stores and reloads events from today")
    func cacheRoundTrip() {
        let service = ICalService()
        // Clear any leftover cache from a previous run.
        service.clearCache()

        let now = Date()
        let event = CalendarEvent(
            id: "test-cache-1",
            title: "Cached Event",
            startDate: now,
            endDate: now.addingTimeInterval(3600),
            calendarTitle: "Test",
            calendarColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
            isAllDay: false
        )
        service.cacheEvents([event])

        let loaded = service.loadCachedEvents()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == "test-cache-1")

        service.clearCache()
    }

    @Test("Empty cache returns empty array")
    func emptyCacheReturnsEmpty() {
        let service = ICalService()
        service.clearCache()
        #expect(service.loadCachedEvents().isEmpty)
    }

    @Test("Legacy UserDefaults keys are purged once")
    func legacyKeysPurged() {
        let suite = UserDefaults(suiteName: "test-legacy-purge-\(UUID().uuidString)")!
        suite.set(Data([0x01, 0x02]), forKey: "cachedICalEvents")
        suite.set(Date(), forKey: "cachedICalEventsDate")

        ICalService.purgeLegacyUserDefaultsCache(suite)

        #expect(suite.data(forKey: "cachedICalEvents") == nil)
        #expect(suite.object(forKey: "cachedICalEventsDate") == nil)
        #expect(suite.bool(forKey: "iCalLegacyCachePurged_v1") == true)

        // Idempotent: re-running doesn't crash and doesn't re-clear.
        suite.set(Data([0x03]), forKey: "cachedICalEvents")
        ICalService.purgeLegacyUserDefaultsCache(suite)
        // Flag is set, so the second call short-circuited and left our value alone.
        #expect(suite.data(forKey: "cachedICalEvents") == Data([0x03]))
    }
}
