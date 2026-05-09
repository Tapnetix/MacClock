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

    @Test("Unfolds RFC 5545 continuation lines (space prefix)")
    func unfoldsContinuationLines() {
        // RFC 5545 §3.1: long content lines are folded by inserting CRLF + a single
        // whitespace octet. To unfold, both the CRLF and the leading whitespace are
        // removed. The remaining characters on the continuation line — including any
        // *additional* leading whitespace — are preserved verbatim.
        //
        // Fixture below: "Long" + CRLF + space + "title that" → "Longtitle that"
        //                "title that" + CRLF + space + " spans lines" → "title that spans lines"
        // (the second fold has TWO spaces; the first is the fold marker, the second is preserved)
        let ics = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\nUID:fold-1@example.com\r\nDTSTART:20260601T100000Z\r\nDTEND:20260601T110000Z\r\nSUMMARY:Long\r\n title that\r\n  spans lines\r\nEND:VEVENT\r\nEND:VCALENDAR"

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")

        #expect(events.count == 1)
        #expect(events[0].title == "Longtitle that spans lines")
    }

    @Test("Parses TZID-anchored DTSTART correctly")
    func parsesTZIDAnchoredDateTime() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:tzid-1@example.com
        DTSTART;TZID=America/New_York:20260601T100000
        DTEND;TZID=America/New_York:20260601T110000
        SUMMARY:NYC Meeting
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")

        #expect(events.count == 1)
        // 10:00 EDT (UTC-4 in June) = 14:00 UTC.
        let utc = TimeZone(identifier: "UTC")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: events[0].startDate)
        #expect(comps.year == 2026)
        #expect(comps.month == 6)
        #expect(comps.day == 1)
        #expect(comps.hour == 14)
    }

    @Test("RRULE FREQ=DAILY expands today's occurrence")
    func rruleDailyExpandsToday() {
        // Anchor RRULE start to "yesterday" so today is occurrence #2.
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yFormatter = DateFormatter()
        yFormatter.dateFormat = "yyyyMMdd"
        yFormatter.locale = Locale(identifier: "en_US_POSIX")
        yFormatter.timeZone = TimeZone.current
        let yStr = yFormatter.string(from: yesterday)

        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:rrule-daily-1@example.com
        DTSTART:\(yStr)T100000Z
        DTEND:\(yStr)T110000Z
        SUMMARY:Daily Standup
        RRULE:FREQ=DAILY;COUNT=3
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")

        // Today should produce one expanded occurrence (the parser only emits today).
        #expect(events.count == 1)
        #expect(events[0].title == "Daily Standup")
    }

    @Test("Malformed: unbalanced VEVENT does not crash")
    func malformedUnbalancedVEvent() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:half-event@example.com
        DTSTART:20260601T100000Z
        SUMMARY:Half written
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")
        // Parser swallows the unterminated event; returns whatever was complete (may be 0).
        #expect(events.count <= 1)
    }

    @Test("Malformed: bad date format yields no event")
    func malformedBadDateFormat() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:bad-date@example.com
        DTSTART:not-a-date
        DTEND:also-not-a-date
        SUMMARY:Garbage
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")
        #expect(events.count == 0)
    }

    @Test("Malformed: completely empty input returns empty array")
    func malformedEmptyInput() {
        let service = ICalService()
        let events = service.parseICS("", feedName: "Test", colorHex: "#FF0000")
        #expect(events.isEmpty)
    }

    @Test("Malformed: garbage non-ICS input returns empty array")
    func malformedGarbageInput() {
        let service = ICalService()
        let events = service.parseICS("<html><body>not ical</body></html>", feedName: "Test", colorHex: "#FF0000")
        #expect(events.isEmpty)
    }

    @Test("fetchEvents throws invalidURL for nonsense URL string")
    func fetchEventsInvalidURL() async {
        let service = ICalService()
        let feed = ICalFeed(
            id: UUID(),
            name: "Bad",
            url: "ht!tp://[not a url",
            isEnabled: true,
            colorHex: "#FF0000"
        )
        do {
            _ = try await service.fetchEvents(from: feed)
            Issue.record("Expected throw")
        } catch ICalError.invalidURL {
            // expected
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("fetchEvents returns empty for disabled feed")
    func fetchEventsDisabledFeed() async throws {
        let service = ICalService()
        let feed = ICalFeed(
            id: UUID(),
            name: "Off",
            url: "https://example.com/cal.ics",
            isEnabled: false,
            colorHex: "#FF0000"
        )
        let events = try await service.fetchEvents(from: feed)
        #expect(events.isEmpty)
    }

    @Test("ICalError descriptions are non-empty")
    func iCalErrorDescriptions() {
        #expect(ICalError.invalidURL.errorDescription?.isEmpty == false)
        #expect(ICalError.invalidContent.errorDescription?.isEmpty == false)
        #expect(ICalError.networkError.errorDescription?.isEmpty == false)
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
