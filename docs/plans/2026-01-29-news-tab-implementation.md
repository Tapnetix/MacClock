# News Tab & Feed Discovery Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split News into its own Settings tab with custom RSS feed management, feed discovery, and ticker navigation.

**Architecture:** Update NewsFeed model with isBuiltIn flag, create FeedDiscoveryService for URL autodiscovery and Feedly API search, add News tab to Settings, update NewsTickerView with hover navigation controls.

**Tech Stack:** Swift, SwiftUI, URLSession for feed discovery, Feedly public API for search.

---

### Task 1: Update NewsFeed Model

**Files:**
- Modify: `MacClock/Models/NewsItem.swift`
- Test: `MacClockTests/NewsFeedTests.swift` (create)

**Step 1: Write the failing test**

Create `MacClockTests/NewsFeedTests.swift`:

```swift
import Testing
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
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter NewsFeedTests`
Expected: FAIL - NewsFeed initializer doesn't accept isBuiltIn parameter

**Step 3: Update NewsFeed model**

Modify `MacClock/Models/NewsItem.swift`:

```swift
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter NewsFeedTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/NewsItem.swift MacClockTests/NewsFeedTests.swift
git commit -m "feat(news): add isBuiltIn flag to NewsFeed model"
```

---

### Task 2: Create DiscoveredFeed Model

**Files:**
- Create: `MacClock/Models/DiscoveredFeed.swift`

**Step 1: Create the model**

Create `MacClock/Models/DiscoveredFeed.swift`:

```swift
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
```

**Step 2: Verify build**

Run: `swift build`
Expected: Build successful

**Step 3: Commit**

```bash
git add MacClock/Models/DiscoveredFeed.swift
git commit -m "feat(news): add DiscoveredFeed model for search results"
```

---

### Task 3: Create FeedDiscoveryService - URL Autodiscovery

**Files:**
- Create: `MacClock/Services/FeedDiscoveryService.swift`
- Test: `MacClockTests/FeedDiscoveryTests.swift` (create)

**Step 1: Write the failing test**

Create `MacClockTests/FeedDiscoveryTests.swift`:

```swift
import Testing
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
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter FeedDiscoveryTests`
Expected: FAIL - FeedDiscoveryService doesn't exist

**Step 3: Implement FeedDiscoveryService**

Create `MacClock/Services/FeedDiscoveryService.swift`:

```swift
import Foundation

actor FeedDiscoveryService {
    private let session = URLSession.shared

    // MARK: - Input Detection

    nonisolated func isURL(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        // Contains a dot and no spaces = likely URL
        return trimmed.contains(".") && !trimmed.contains(" ")
    }

    // MARK: - RSS Link Parsing

    nonisolated func parseRSSLinks(from html: String, baseURL: URL) -> [DiscoveredFeed] {
        var feeds: [DiscoveredFeed] = []

        // Match <link> tags with RSS/Atom types
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
            } else if href.hasPrefix("/") {
                feedURL = baseURL.scheme! + "://" + baseURL.host! + href
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

        for path in commonPaths {
            let feedURL = baseURL.scheme! + "://" + baseURL.host! + path
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter FeedDiscoveryTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Services/FeedDiscoveryService.swift MacClockTests/FeedDiscoveryTests.swift
git commit -m "feat(news): add FeedDiscoveryService with URL autodiscovery and Feedly search"
```

---

### Task 4: Add News Tab to Settings

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add news case to SettingsTab enum**

In `MacClock/Views/SettingsView.swift`, update the enum (around line 6-24):

```swift
enum SettingsTab: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case window = "Window"
    case location = "Location"
    case worldClocks = "World Clocks"
    case news = "News"
    case extras = "Extras"

    var icon: String {
        switch self {
        case .general: return "clock.fill"
        case .appearance: return "paintbrush.fill"
        case .window: return "macwindow"
        case .location: return "location.fill"
        case .worldClocks: return "globe"
        case .news: return "newspaper.fill"
        case .extras: return "sparkles"
        }
    }
}
```

**Step 2: Add case to tab content switch**

In the `SettingsView` body, add the news case to the switch statement (around line 60-80):

```swift
                    case .news:
                        NewsTabView(settings: settings)
```

**Step 3: Verify build**

Run: `swift build`
Expected: FAIL - NewsTabView doesn't exist yet (expected, we'll create it next)

**Step 4: Commit enum changes**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat(news): add News tab to Settings tabs enum"
```

---

### Task 5: Create NewsTabView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift` (add NewsTabView struct)

**Step 1: Create NewsTabView struct**

Add this struct to `MacClock/Views/SettingsView.swift` (after ExtrasTabView, before SettingsSection):

```swift
// MARK: - News Tab

struct NewsTabView: View {
    @Bindable var settings: AppSettings
    @State private var feedDiscoveryService = FeedDiscoveryService()
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var searchResults: [DiscoveredFeed] = []
    @State private var showSearchResults = false
    @State private var showManualAdd = false
    @State private var searchError: String?

    var body: some View {
        SettingsSection(title: "News Ticker") {
            Toggle("Enable News Ticker", isOn: $settings.newsTickerEnabled)

            if settings.newsTickerEnabled {
                LabeledContent("Style") {
                    Picker("", selection: $settings.newsTickerStyle) {
                        ForEach(NewsTickerStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }

                if settings.newsTickerStyle == .scrolling {
                    LabeledContent("Speed") {
                        HStack {
                            Slider(value: $settings.newsScrollSpeed, in: 20...100, step: 10)
                                .frame(width: 100)
                            Text("\(Int(settings.newsScrollSpeed))")
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                        }
                    }
                } else {
                    LabeledContent("Rotate Every") {
                        HStack {
                            Slider(value: $settings.newsRotateInterval, in: 5...30, step: 5)
                                .frame(width: 100)
                            Text("\(Int(settings.newsRotateInterval))s")
                                .foregroundStyle(.secondary)
                                .frame(width: 35)
                        }
                    }
                }
            }
        }

        SettingsSection(title: "Your Feeds") {
            // Search field
            HStack {
                TextField("Search feeds or enter URL...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await performSearch() }
                    }

                Button {
                    Task { await performSearch() }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .disabled(searchQuery.isEmpty || isSearching)
            }

            if let error = searchError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Feed list
            ForEach($settings.newsFeeds) { $feed in
                FeedRow(feed: $feed, canDelete: !feed.isBuiltIn) {
                    settings.newsFeeds.removeAll { $0.id == feed.id }
                }
            }

            Button {
                showManualAdd = true
            } label: {
                Label("Add Feed Manually", systemImage: "plus.circle")
            }
            .padding(.top, 4)
        }
        .sheet(isPresented: $showSearchResults) {
            FeedSearchResultsSheet(
                results: searchResults,
                isPresented: $showSearchResults,
                onAdd: { feed in
                    addFeed(feed)
                }
            )
        }
        .sheet(isPresented: $showManualAdd) {
            ManualFeedSheet(isPresented: $showManualAdd) { name, url in
                let feed = NewsFeed(
                    id: UUID(),
                    name: name,
                    url: url,
                    isEnabled: true,
                    isBuiltIn: false
                )
                settings.newsFeeds.append(feed)
            }
        }
    }

    private func performSearch() async {
        guard !searchQuery.isEmpty else { return }

        isSearching = true
        searchError = nil

        do {
            if feedDiscoveryService.isURL(searchQuery) {
                searchResults = try await feedDiscoveryService.discoverFeeds(from: searchQuery)
            } else {
                searchResults = try await feedDiscoveryService.searchFeeds(query: searchQuery)
            }

            if searchResults.isEmpty {
                searchError = "No feeds found"
            } else {
                showSearchResults = true
            }
        } catch {
            searchError = error.localizedDescription
        }

        isSearching = false
    }

    private func addFeed(_ discovered: DiscoveredFeed) {
        let feed = discovered.toNewsFeed()
        // Avoid duplicates
        if !settings.newsFeeds.contains(where: { $0.url == feed.url }) {
            settings.newsFeeds.append(feed)
        }
    }
}

// MARK: - Feed Row

struct FeedRow: View {
    @Binding var feed: NewsFeed
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: $feed.isEnabled)
                .labelsHidden()
                .toggleStyle(.checkbox)

            Text(feed.name)

            Spacer()

            Text(feed.isBuiltIn ? "Built-in" : "Custom")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)

            if canDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Search Results Sheet

struct FeedSearchResultsSheet: View {
    let results: [DiscoveredFeed]
    @Binding var isPresented: Bool
    let onAdd: (DiscoveredFeed) -> Void

    @State private var addedFeedIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Found \(results.count) feed\(results.count == 1 ? "" : "s")")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(results) { feed in
                        FeedSearchResultRow(
                            feed: feed,
                            isAdded: addedFeedIDs.contains(feed.id),
                            onAdd: {
                                onAdd(feed)
                                addedFeedIDs.insert(feed.id)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 350)
    }
}

struct FeedSearchResultRow: View {
    let feed: DiscoveredFeed
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(feed.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let website = feed.websiteURL {
                        Text(URL(string: website)?.host ?? website)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let count = feed.subscriberCount, count > 0 {
                        Text(formatSubscribers(count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let desc = feed.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button(isAdded ? "Added" : "Add") {
                onAdd()
            }
            .disabled(isAdded)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func formatSubscribers(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM readers", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.0fK readers", Double(count) / 1_000)
        } else {
            return "\(count) readers"
        }
    }
}

// MARK: - Manual Feed Sheet

struct ManualFeedSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, String) -> Void

    @State private var name = ""
    @State private var url = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Feed Manually")
                .font(.headline)

            TextField("Feed Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("RSS Feed URL", text: $url)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Add") {
                    onAdd(name, url)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || url.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
```

**Step 2: Verify build**

Run: `swift build`
Expected: PASS

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat(news): add NewsTabView with feed search and management"
```

---

### Task 6: Remove News from ExtrasTabView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Update ExtrasTabView to remove News section**

Find `ExtrasTabView` in `SettingsView.swift` and remove the entire "News Ticker" SettingsSection. The updated ExtrasTabView should only contain Calendar and Alarms:

```swift
// MARK: - Extras Tab

struct ExtrasTabView: View {
    @Bindable var settings: AppSettings
    let calendarService: CalendarService
    @Binding var showAlarmPanel: Bool

    var body: some View {
        SettingsSection(title: "Calendar") {
            Toggle("Enable Calendar", isOn: $settings.calendarEnabled)

            if settings.calendarEnabled {
                if calendarService.authorizationStatus != .fullAccess && calendarService.authorizationStatus != .authorized {
                    Button("Grant Calendar Access") {
                        Task { await calendarService.requestAccess() }
                    }
                } else {
                    Toggle("Show Next Event Countdown", isOn: $settings.calendarShowCountdown)
                    Toggle("Show Agenda Panel", isOn: $settings.calendarShowAgenda)

                    if settings.calendarShowAgenda {
                        LabeledContent("Panel Position") {
                            Picker("", selection: $settings.calendarAgendaPosition) {
                                ForEach(WorldClocksPosition.allCases, id: \.self) { pos in
                                    Text(pos.rawValue).tag(pos)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }
                    }

                    if !calendarService.availableCalendars.isEmpty {
                        Text("Calendars")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                            Toggle(calendar.title, isOn: Binding(
                                get: { settings.selectedCalendarIDs.contains(calendar.calendarIdentifier) },
                                set: { enabled in
                                    if enabled {
                                        settings.selectedCalendarIDs.append(calendar.calendarIdentifier)
                                    } else {
                                        settings.selectedCalendarIDs.removeAll { $0 == calendar.calendarIdentifier }
                                    }
                                }
                            ))
                        }
                    }
                }
            }
        }

        SettingsSection(title: "Alarms & Timers") {
            Button("Open Alarms, Timer & Stopwatch") {
                showAlarmPanel = true
            }
        }
    }
}
```

**Step 2: Verify build**

Run: `swift build`
Expected: PASS

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "refactor(news): remove News section from ExtrasTabView"
```

---

### Task 7: Update NewsTickerView with Hover Navigation

**Files:**
- Modify: `MacClock/Views/NewsTickerView.swift`

**Step 1: Rewrite NewsTickerView with navigation**

Replace the entire content of `MacClock/Views/NewsTickerView.swift`:

```swift
import SwiftUI
import AppKit

struct NewsTickerView: View {
    let settings: AppSettings
    let theme: ColorTheme
    let newsItems: [NewsItem]

    @State private var scrollOffset: CGFloat = 0
    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0
    @State private var isHovering = false
    @State private var isPaused = false
    @State private var scrollTimer: Timer?
    @State private var rotateTimer: Timer?
    @State private var pauseTimer: Timer?

    var body: some View {
        Group {
            if settings.newsTickerStyle == .scrolling {
                scrollingTicker
            } else {
                rotatingTicker
            }
        }
        .frame(height: 30)
        .background(Color.black.opacity(0.5))
        .onDisappear {
            scrollTimer?.invalidate()
            rotateTimer?.invalidate()
            pauseTimer?.invalidate()
        }
    }

    private var scrollingTicker: some View {
        GeometryReader { geometry in
            let text = newsItems.map { $0.displayTitle }.joined(separator: "  •  ")

            HStack(spacing: 0) {
                // Left navigation arrow
                if isHovering {
                    Button {
                        navigatePrevious()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.primaryColor.opacity(0.8))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(x: scrollOffset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                    .onTapGesture {
                        openCurrentItem()
                    }

                // Right navigation arrow
                if isHovering {
                    Button {
                        navigateNext()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.primaryColor.opacity(0.8))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
            .onAppear {
                startScrolling(containerWidth: geometry.size.width)
            }
        }
    }

    private var rotatingTicker: some View {
        Group {
            if !newsItems.isEmpty {
                let item = newsItems[currentIndex % newsItems.count]

                HStack(spacing: 0) {
                    // Left navigation arrow
                    if isHovering {
                        Button {
                            navigatePrevious()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.primaryColor.opacity(0.8))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }

                    Text(item.displayTitle)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.primaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .opacity(opacity)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            openCurrentItem()
                        }

                    // Right navigation arrow
                    if isHovering {
                        Button {
                            navigateNext()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.primaryColor.opacity(0.8))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isHovering)
                .onHover { hovering in
                    isHovering = hovering
                }
                .onAppear {
                    startRotating()
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Navigation

    private func navigatePrevious() {
        pauseAutoAdvance()

        if settings.newsTickerStyle == .rotating {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex = (currentIndex - 1 + newsItems.count) % newsItems.count
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1
                }
            }
        } else {
            // For scrolling, jump to previous logical position
            currentIndex = (currentIndex - 1 + newsItems.count) % newsItems.count
        }
    }

    private func navigateNext() {
        pauseAutoAdvance()

        if settings.newsTickerStyle == .rotating {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex = (currentIndex + 1) % newsItems.count
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1
                }
            }
        } else {
            currentIndex = (currentIndex + 1) % newsItems.count
        }
    }

    private func pauseAutoAdvance() {
        isPaused = true
        pauseTimer?.invalidate()
        pauseTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            isPaused = false
        }
    }

    private func openCurrentItem() {
        guard !newsItems.isEmpty else { return }
        let index = currentIndex % newsItems.count
        if let url = newsItems[index].link {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Auto-Advance

    private func startScrolling(containerWidth: CGFloat) {
        scrollOffset = containerWidth

        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            guard !isPaused else { return }
            scrollOffset -= settings.newsScrollSpeed * 0.03
            if scrollOffset < -2000 {
                scrollOffset = containerWidth
            }
        }
    }

    private func startRotating() {
        rotateTimer = Timer.scheduledTimer(withTimeInterval: settings.newsRotateInterval, repeats: true) { _ in
            guard !isPaused else { return }

            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex += 1
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview {
    let settings = AppSettings()
    let items = [
        NewsItem(title: "Breaking news headline here", link: nil, source: "BBC", publishedDate: nil),
        NewsItem(title: "Another important story", link: nil, source: "Reuters", publishedDate: nil),
    ]
    return NewsTickerView(settings: settings, theme: .classicWhite, newsItems: items)
        .frame(width: 500)
        .background(.black)
}
```

**Step 2: Verify build**

Run: `swift build`
Expected: PASS

**Step 3: Commit**

```bash
git add MacClock/Views/NewsTickerView.swift
git commit -m "feat(news): add hover-to-reveal navigation to NewsTickerView"
```

---

### Task 8: Run All Tests and Final Verification

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 2: Build the app**

Run: `swift build`
Expected: Build successful

**Step 3: Final commit with all changes**

If any uncommitted changes remain:

```bash
git status
git add -A
git commit -m "feat(news): complete News tab implementation"
```

---

## Summary

This plan implements:
1. ✅ Updated `NewsFeed` model with `isBuiltIn` flag
2. ✅ `DiscoveredFeed` model for search results
3. ✅ `FeedDiscoveryService` with URL autodiscovery and Feedly search
4. ✅ New "News" tab in Settings
5. ✅ `NewsTabView` with feed management UI
6. ✅ Feed search/discovery sheets
7. ✅ Manual feed addition
8. ✅ News ticker hover navigation
9. ✅ Removed News from Extras tab
