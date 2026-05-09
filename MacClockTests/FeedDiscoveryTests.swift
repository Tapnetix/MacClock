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

    @Test("Returns empty array for HTML with no link tags")
    func noLinksInHTML() {
        let html = "<html><body><p>just text</p></body></html>"
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)
        #expect(feeds.isEmpty)
    }

    @Test("Skips link tags without href")
    func skipsLinksWithoutHref() {
        let html = """
        <html><head>
            <link rel="alternate" type="application/rss+xml" title="Broken">
            <link rel="alternate" type="application/rss+xml" title="Good" href="https://example.com/feed.xml">
        </head></html>
        """
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)
        #expect(feeds.count == 1)
        #expect(feeds[0].title == "Good")
    }

    @Test("Resolves relative href starting with /")
    func resolvesRelativeHref() {
        let html = """
        <link rel="alternate" type="application/rss+xml" title="Rel" href="/feed.xml">
        """
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com/blog")!)
        #expect(feeds.count == 1)
        #expect(feeds[0].feedURL == "https://example.com/feed.xml")
    }

    @Test("Resolves relative href without leading /")
    func resolvesRelativeNoSlash() {
        let html = """
        <link rel="alternate" type="application/rss+xml" title="Rel" href="feed.xml">
        """
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)
        #expect(feeds.count == 1)
        // Concatenation pattern: baseURL + "/" + href
        #expect(feeds[0].feedURL == "https://example.com/feed.xml")
    }

    @Test("Handles mixed RSS and Atom feed types in same page")
    func mixedFeedTypes() {
        let html = """
        <html><head>
            <link rel="alternate" type="application/rss+xml" title="RSS" href="/rss.xml">
            <link rel="alternate" type="application/atom+xml" title="Atom" href="/atom.xml">
            <link rel="alternate" type="application/json" title="JSON Feed" href="/feed.json">
        </head></html>
        """
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)
        // Only RSS and Atom are recognized; JSON Feed is ignored.
        #expect(feeds.count == 2)
        let titles = feeds.map { $0.title }
        #expect(titles.contains("RSS"))
        #expect(titles.contains("Atom"))
    }

    @Test("Falls back to default title when missing")
    func defaultTitle() {
        let html = """
        <link rel="alternate" type="application/rss+xml" href="/feed.xml">
        """
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)
        #expect(feeds.count == 1)
        #expect(feeds[0].title == "RSS Feed")
    }

    @Test("Handles malformed HTML without crashing")
    func malformedHTML() {
        let html = "<<>>not really << html<<<<"
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)
        #expect(feeds.isEmpty)
    }

    @Test("Handles empty HTML")
    func emptyHTML() {
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: "", baseURL: URL(string: "https://example.com")!)
        #expect(feeds.isEmpty)
    }

    @Test("Recognized feed types: RSS and Atom, but not RDF")
    func feedTypeRecognition() {
        let html = """
        <link rel="alternate" type="application/rdf+xml" title="RDF" href="/rdf.xml">
        """
        let service = FeedDiscoveryService()
        let feeds = service.parseRSSLinks(from: html, baseURL: URL(string: "https://example.com")!)
        // RDF is not currently recognized.
        #expect(feeds.isEmpty)
    }

    @Test("isURL trims whitespace before deciding")
    func isURLTrimsWhitespace() {
        let service = FeedDiscoveryService()
        #expect(service.isURL("  https://example.com  ") == true)
        #expect(service.isURL("  hello world  ") == false)
    }

    @Test("isURL rejects spaces")
    func isURLRejectsSpaces() {
        let service = FeedDiscoveryService()
        // Even with a dot, embedded spaces disqualify.
        #expect(service.isURL("example .com") == false)
    }

    @Test("FeedDiscoveryError descriptions are non-empty")
    func feedDiscoveryErrorDescriptions() {
        #expect(FeedDiscoveryError.invalidURL.errorDescription?.isEmpty == false)
        #expect(FeedDiscoveryError.invalidResponse.errorDescription?.isEmpty == false)
        #expect(FeedDiscoveryError.noFeedsFound.errorDescription?.isEmpty == false)
    }
}
