import Testing
import Foundation
@testable import MacClock

@Suite("ICalFeed Tests")
struct ICalFeedTests {
    @Test("ICalFeed stores properties correctly")
    func iCalFeedStoresProperties() {
        let feed = ICalFeed(
            id: UUID(),
            name: "Test Calendar",
            url: "https://example.com/calendar.ics",
            isEnabled: true,
            colorHex: "#FF0000"
        )
        #expect(feed.name == "Test Calendar")
        #expect(feed.url == "https://example.com/calendar.ics")
        #expect(feed.isEnabled == true)
        #expect(feed.colorHex == "#FF0000")
    }

    @Test("ICalFeed is Codable")
    func iCalFeedIsCodable() throws {
        let feed = ICalFeed(
            id: UUID(),
            name: "Work",
            url: "https://example.com/work.ics",
            isEnabled: true,
            colorHex: "#0000FF"
        )
        let data = try JSONEncoder().encode(feed)
        let decoded = try JSONDecoder().decode(ICalFeed.self, from: data)
        #expect(decoded.name == feed.name)
        #expect(decoded.url == feed.url)
        #expect(decoded.colorHex == feed.colorHex)
    }

    @Test("ICalFeed color presets are available")
    func colorPresetsAvailable() {
        let presets = ICalFeed.colorPresets
        #expect(presets.count >= 8)
        #expect(presets.contains { $0.name == "Red" })
        #expect(presets.contains { $0.name == "Blue" })
    }
}
