import Testing
import Foundation
@testable import MacClock

@Suite("NewsService Tests")
struct NewsServiceTests {

    @Test("Parses standard RSS 2.0 feed")
    func parsesRSS2() {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0">
          <channel>
            <title>Test Feed</title>
            <item>
              <title>First Story</title>
              <link>https://example.com/1</link>
              <pubDate>Thu, 09 May 2026 12:00:00 +0000</pubDate>
            </item>
            <item>
              <title>Second Story</title>
              <link>https://example.com/2</link>
              <pubDate>Wed, 08 May 2026 09:30:00 +0000</pubDate>
            </item>
          </channel>
        </rss>
        """.data(using: .utf8)!

        let parser = RSSParser(source: "Test")
        let items = parser.parse(data: xml)
        #expect(items.count == 2)
        #expect(items[0].title == "First Story")
        #expect(items[0].source == "Test")
        #expect(items[0].link?.absoluteString == "https://example.com/1")
        #expect(items[0].publishedDate != nil)
    }

    @Test("Parses Atom feed")
    func parsesAtom() {
        let xml = """
        <?xml version="1.0"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Atom Feed</title>
          <entry>
            <title>Atom Story</title>
            <link href="https://example.com/atom-1" />
            <updated>2026-05-09T12:00:00Z</updated>
          </entry>
        </feed>
        """.data(using: .utf8)!

        let parser = RSSParser(source: "Atom")
        let items = parser.parse(data: xml)
        #expect(items.count == 1)
        #expect(items[0].title == "Atom Story")
        #expect(items[0].link?.absoluteString == "https://example.com/atom-1")
    }

    @Test("Skips items with empty titles")
    func skipsEmptyTitles() {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0">
          <channel>
            <item>
              <title></title>
              <link>https://example.com/empty</link>
            </item>
            <item>
              <title>Good Story</title>
              <link>https://example.com/good</link>
            </item>
          </channel>
        </rss>
        """.data(using: .utf8)!

        let parser = RSSParser(source: "Test")
        let items = parser.parse(data: xml)
        #expect(items.count == 1)
        #expect(items[0].title == "Good Story")
    }

    @Test("Returns empty array on malformed XML")
    func malformedXML() {
        let xml = "<not really xml".data(using: .utf8)!
        let parser = RSSParser(source: "Test")
        let items = parser.parse(data: xml)
        #expect(items.isEmpty)
    }

    @Test("Returns empty array on completely empty data")
    func emptyData() {
        let parser = RSSParser(source: "Test")
        let items = parser.parse(data: Data())
        #expect(items.isEmpty)
    }

    @Test("Handles missing optional fields (no pubDate)")
    func missingOptionalFields() {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>No Date Story</title>
              <link>https://example.com/no-date</link>
            </item>
          </channel>
        </rss>
        """.data(using: .utf8)!

        let parser = RSSParser(source: "Test")
        let items = parser.parse(data: xml)
        #expect(items.count == 1)
        #expect(items[0].title == "No Date Story")
        #expect(items[0].publishedDate == nil)
    }

    @Test("Date parser handles RFC 822 format")
    func dateParserRFC822() {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>Dated</title>
              <pubDate>Sat, 09 May 2026 12:00:00 +0000</pubDate>
            </item>
          </channel>
        </rss>
        """.data(using: .utf8)!

        let parser = RSSParser(source: "Test")
        let items = parser.parse(data: xml)
        #expect(items.count == 1)
        #expect(items[0].publishedDate != nil)
    }

    @Test("Date parser handles ISO 8601 format")
    func dateParserISO8601() {
        let xml = """
        <?xml version="1.0"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <title>ISO Dated</title>
            <updated>2026-05-09T12:00:00Z</updated>
          </entry>
        </feed>
        """.data(using: .utf8)!

        let parser = RSSParser(source: "Test")
        let items = parser.parse(data: xml)
        #expect(items.count == 1)
        #expect(items[0].publishedDate != nil)
    }
}
