import Foundation

actor NewsService: NSObject, XMLParserDelegate {
    private var newsItems: [NewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentSource = ""
    private var isInItem = false

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    func fetchNews(from feeds: [NewsFeed]) async -> [NewsItem] {
        var allItems: [NewsItem] = []

        for feed in feeds where feed.isEnabled {
            if let items = await fetchFeed(feed) {
                allItems.append(contentsOf: items)
            }
        }

        // Sort by date, most recent first
        return allItems.sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }

    private func fetchFeed(_ feed: NewsFeed) async -> [NewsItem]? {
        guard let url = URL(string: feed.url) else { return nil }

        do {
            let (data, _) = try await session.data(from: url)
            return parseFeed(data: data, source: feed.name)
        } catch {
            print("Failed to fetch feed \(feed.name): \(error)")
            return nil
        }
    }

    nonisolated private func parseFeed(data: Data, source: String) -> [NewsItem] {
        let parser = RSSParser(source: source)
        return parser.parse(data: data)
    }
}

// Separate non-actor class for XML parsing
private class RSSParser: NSObject, XMLParserDelegate {
    private var items: [NewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var isInItem = false
    private let source: String

    init(source: String) {
        self.source = source
    }

    func parse(data: Data) -> [NewsItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" || elementName == "entry" {
            isInItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
        }
        if elementName == "link", let href = attributeDict["href"] {
            currentLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInItem else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        case "pubDate", "published", "updated":
            currentPubDate += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            let item = NewsItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)),
                source: source,
                publishedDate: parseDate(currentPubDate)
            )
            if !item.title.isEmpty {
                items.append(item)
            }
            isInItem = false
        }
    }

    private func parseDate(_ string: String) -> Date? {
        let formatters = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }
        return nil
    }
}
