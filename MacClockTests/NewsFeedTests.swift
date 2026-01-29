import Testing
import Foundation
@testable import MacClock

@Suite("NewsFeed Tests")
struct NewsFeedTests {
    @Test("NewsFeed stores isBuiltIn flag")
    func newsFeedStoresIsBuiltIn() {
        let feed = NewsFeed(
            id: UUID(),
            name: "Test Feed",
            url: "https://example.com/feed",
            isEnabled: true,
            isBuiltIn: false
        )
        #expect(feed.isBuiltIn == false)
        #expect(feed.name == "Test Feed")
    }

    @Test("Built-in feeds have isBuiltIn true")
    func builtInFeedsHaveFlag() {
        let builtIns = NewsFeed.builtInFeeds
        for feed in builtIns {
            #expect(feed.isBuiltIn == true)
        }
    }

    @Test("NewsFeed is Codable with isBuiltIn")
    func newsFeedIsCodable() throws {
        let feed = NewsFeed(
            id: UUID(),
            name: "Custom",
            url: "https://example.com/rss",
            isEnabled: true,
            isBuiltIn: false
        )
        let data = try JSONEncoder().encode(feed)
        let decoded = try JSONDecoder().decode(NewsFeed.self, from: data)
        #expect(decoded.name == feed.name)
        #expect(decoded.isBuiltIn == false)
    }
}
