import Foundation

struct NewsItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let link: URL?
    let source: String
    let publishedDate: Date?

    var displayTitle: String {
        "\(source): \(title)"
    }
}

struct NewsFeed: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var isEnabled: Bool
    var isBuiltIn: Bool

    static let builtInFeeds: [NewsFeed] = [
        NewsFeed(id: UUID(), name: "BBC World", url: "https://feeds.bbci.co.uk/news/world/rss.xml", isEnabled: true, isBuiltIn: true),
        NewsFeed(id: UUID(), name: "Reuters", url: "https://www.reutersagency.com/feed/?best-regions=europe&post_type=best", isEnabled: false, isBuiltIn: true),
        NewsFeed(id: UUID(), name: "NPR News", url: "https://feeds.npr.org/1001/rss.xml", isEnabled: false, isBuiltIn: true),
        NewsFeed(id: UUID(), name: "The Guardian", url: "https://www.theguardian.com/world/rss", isEnabled: false, isBuiltIn: true),
    ]
}
