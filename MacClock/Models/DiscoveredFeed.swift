import Foundation

struct DiscoveredFeed: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let feedURL: String
    let websiteURL: String?
    let description: String?
    let subscriberCount: Int?

    func toNewsFeed() -> NewsFeed {
        NewsFeed(
            id: UUID(),
            name: title,
            url: feedURL,
            isEnabled: true,
            isBuiltIn: false
        )
    }
}
