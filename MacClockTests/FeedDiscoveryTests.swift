import Testing
import Foundation
@testable import MacClock

@Suite("FeedDiscovery Tests")
struct FeedDiscoveryTests {
    @Test("Parses RSS link tags from HTML")
    func parsesRSSLinkTags() {
        let html = """
        <html>
        <head>
            <link rel="alternate" type="application/rss+xml" title="Main Feed" href="https://example.com/feed.xml">
            <link rel="alternate" type="application/atom+xml" title="Atom Feed" href="/atom.xml">
        </head>
        </html>
        """
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)

        #expect(feeds.count == 2)
        #expect(feeds[0].title == "Main Feed")
        #expect(feeds[0].feedURL == "https://example.com/feed.xml")
        #expect(feeds[1].feedURL == "https://example.com/atom.xml")
    }

    @Test("Detects URL vs keyword input")
    func detectsInputType() {
        let service = FeedDiscoveryService()
        #expect(service.isURL("https://example.com") == true)
        #expect(service.isURL("example.com") == true)
        #expect(service.isURL("tech news") == false)
        #expect(service.isURL("techcrunch") == false)
    }
}
