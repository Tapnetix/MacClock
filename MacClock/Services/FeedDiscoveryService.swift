import Foundation

actor FeedDiscoveryService {
    private let session = URLSession.standardConfigured

    // MARK: - Input Detection

    nonisolated func isURL(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        // Contains a dot and no spaces = likely URL
        return trimmed.contains(".") && !trimmed.contains(" ")
    }

    // MARK: - RSS Link Parsing

    nonisolated func parseRSSLinks(from html: String, baseURL: URL) -> [DiscoveredFeed] {
        var feeds: [DiscoveredFeed] = []

        // Match <link> tags with rel="alternate"
        let pattern = #"<link[^>]+rel=["\']alternate["\'][^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return feeds
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard let matchRange = Range(match.range, in: html) else { continue }
            let linkTag = String(html[matchRange])

            // Check if it's RSS or Atom
            guard linkTag.contains("application/rss+xml") || linkTag.contains("application/atom+xml") else {
                continue
            }

            // Extract href
            guard let href = extractAttribute("href", from: linkTag) else { continue }

            // Extract title
            let title = extractAttribute("title", from: linkTag) ?? "RSS Feed"

            // Resolve relative URLs
            let feedURL: String
            if href.hasPrefix("http") {
                feedURL = href
            } else if href.hasPrefix("/"),
                      let scheme = baseURL.scheme,
                      let host = baseURL.host {
                feedURL = scheme + "://" + host + href
            } else {
                feedURL = baseURL.absoluteString + "/" + href
            }

            feeds.append(DiscoveredFeed(
                title: title,
                feedURL: feedURL,
                websiteURL: baseURL.absoluteString,
                description: nil,
                subscriberCount: nil
            ))
        }

        return feeds
    }

    private nonisolated func extractAttribute(_ name: String, from tag: String) -> String? {
        let pattern = #"\#(name)=["\']([^"\']+)["\']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(tag.startIndex..., in: tag)
        guard let match = regex.firstMatch(in: tag, options: [], range: range),
              let valueRange = Range(match.range(at: 1), in: tag) else {
            return nil
        }
        return String(tag[valueRange])
    }

    // MARK: - URL Discovery

    func discoverFeeds(from urlString: String) async throws -> [DiscoveredFeed] {
        var urlStr = urlString.trimmingCharacters(in: .whitespaces)
        if !urlStr.hasPrefix("http") {
            urlStr = "https://" + urlStr
        }

        guard let url = URL(string: urlStr) else {
            throw FeedDiscoveryError.invalidURL
        }

        // Fetch the page
        let (data, _) = try await session.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw FeedDiscoveryError.invalidResponse
        }

        // Parse RSS links
        var feeds = parseRSSLinks(from: html, baseURL: url)

        // If no feeds found, try common paths
        if feeds.isEmpty {
            feeds = await tryCommonFeedPaths(baseURL: url)
        }

        return feeds
    }

    private func tryCommonFeedPaths(baseURL: URL) async -> [DiscoveredFeed] {
        let commonPaths = ["/feed", "/rss", "/feed.xml", "/rss.xml", "/atom.xml", "/feed/rss"]
        var feeds: [DiscoveredFeed] = []

        guard let scheme = baseURL.scheme, let host = baseURL.host else {
            return feeds
        }

        for path in commonPaths {
            let feedURL = scheme + "://" + host + path
            guard let url = URL(string: feedURL) else { continue }

            do {
                let (data, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let content = String(data: data, encoding: .utf8),
                   content.contains("<rss") || content.contains("<feed") || content.contains("<channel") {
                    feeds.append(DiscoveredFeed(
                        title: baseURL.host ?? "RSS Feed",
                        feedURL: feedURL,
                        websiteURL: baseURL.absoluteString,
                        description: nil,
                        subscriberCount: nil
                    ))
                    break // Found one, stop trying
                }
            } catch {
                continue
            }
        }

        return feeds
    }

    // MARK: - Feedly Search

    func searchFeeds(query: String) async throws -> [DiscoveredFeed] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://cloud.feedly.com/v3/search/feeds?query=\(encoded)&count=10"

        guard let url = URL(string: urlString) else {
            throw FeedDiscoveryError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(FeedlySearchResponse.self, from: data)

        return response.results.map { result in
            DiscoveredFeed(
                title: result.title,
                feedURL: result.feedId.replacingOccurrences(of: "feed/", with: ""),
                websiteURL: result.website,
                description: result.description,
                subscriberCount: result.subscribers
            )
        }
    }
}

// MARK: - Feedly Response Models

struct FeedlySearchResponse: Codable {
    let results: [FeedlyFeedResult]
}

struct FeedlyFeedResult: Codable {
    let feedId: String
    let title: String
    let website: String?
    let description: String?
    let subscribers: Int?
}

// MARK: - Errors

enum FeedDiscoveryError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noFeedsFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Could not read response"
        case .noFeedsFound: return "No RSS feeds found"
        }
    }
}
