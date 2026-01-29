# MacClock Phase 3 & 4 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add information display features (world clocks, calendar, news ticker) in Phase 3, and full alarm/timer/stopwatch functionality in Phase 4.

**Architecture:** Create dedicated services for each feature (WorldClockService, CalendarService, NewsService, AlarmService). Use EventKit for calendar access, RSS parsing for news. Alarms use UserNotifications framework. Each feature has toggleable UI components that integrate into MainClockView.

**Tech Stack:** SwiftUI, EventKit (calendar), UserNotifications (alarms), XMLParser (RSS), Combine (timers)

---

## Phase 3: Information Display

---

### Task 1: Create WorldClock Model

**Files:**
- Create: `MacClock/Models/WorldClock.swift`
- Test: `MacClockTests/WorldClockTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/WorldClockTests.swift`:

```swift
import Testing
import Foundation
@testable import MacClock

@Suite("WorldClock Tests")
struct WorldClockTests {

    @Test("WorldClock stores city and timezone")
    func worldClockProperties() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "New York",
            timezoneIdentifier: "America/New_York"
        )
        #expect(clock.cityName == "New York")
        #expect(clock.timezoneIdentifier == "America/New_York")
    }

    @Test("WorldClock calculates current time")
    func currentTime() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "London",
            timezoneIdentifier: "Europe/London"
        )
        let time = clock.currentTimeString(use24Hour: false)
        #expect(!time.isEmpty)
    }

    @Test("WorldClock shows timezone abbreviation")
    func timezoneAbbreviation() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "Tokyo",
            timezoneIdentifier: "Asia/Tokyo"
        )
        #expect(clock.timezoneAbbreviation == "JST")
    }

    @Test("WorldClock calculates day difference")
    func dayDifference() {
        let clock = WorldClock(
            id: UUID(),
            cityName: "Tokyo",
            timezoneIdentifier: "Asia/Tokyo"
        )
        // Day difference is relative to local time
        let diff = clock.dayDifferenceFromLocal
        #expect(diff >= -1 && diff <= 1)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WorldClockTests 2>&1 | head -20`
Expected: FAIL with "cannot find 'WorldClock' in scope"

**Step 3: Write minimal implementation**

Create `MacClock/Models/WorldClock.swift`:

```swift
import Foundation

struct WorldClock: Identifiable, Codable, Equatable {
    let id: UUID
    var cityName: String
    var timezoneIdentifier: String

    var timezone: TimeZone? {
        TimeZone(identifier: timezoneIdentifier)
    }

    var timezoneAbbreviation: String {
        timezone?.abbreviation() ?? ""
    }

    var dayDifferenceFromLocal: Int {
        guard let tz = timezone else { return 0 }
        let now = Date()
        let localCalendar = Calendar.current
        let remoteCalendar: Calendar = {
            var cal = Calendar.current
            cal.timeZone = tz
            return cal
        }()

        let localDay = localCalendar.component(.day, from: now)
        let remoteDay = remoteCalendar.component(.day, from: now)

        if remoteDay > localDay { return 1 }
        if remoteDay < localDay { return -1 }
        return 0
    }

    func currentTimeString(use24Hour: Bool) -> String {
        guard let tz = timezone else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: Date())
    }

    func currentDate() -> Date {
        Date()
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter WorldClockTests`
Expected: PASS (4 tests)

**Step 5: Commit**

```bash
git add MacClock/Models/WorldClock.swift MacClockTests/WorldClockTests.swift
git commit -m "feat: add WorldClock model"
```

---

### Task 2: Add World Clock Settings to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`
- Test: `MacClockTests/AppSettingsTests.swift`

**Step 1: Write the failing test**

Add to `MacClockTests/AppSettingsTests.swift`:

```swift
@Test("World clocks default to empty")
func worldClocksDefault() {
    let defaults = UserDefaults(suiteName: "test-worldclocks")!
    defaults.removePersistentDomain(forName: "test-worldclocks")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.worldClocks.isEmpty)
    #expect(settings.worldClocksEnabled == false)
    #expect(settings.worldClocksPosition == .bottom)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsTests 2>&1 | head -20`
Expected: FAIL

**Step 3: Write minimal implementation**

Add enum to `MacClock/Models/AppSettings.swift` after `ClockStyle`:

```swift
enum WorldClocksPosition: String, CaseIterable {
    case bottom = "Bottom Bar"
    case side = "Side Panel"
}
```

Add properties after `autoThemeMode`:

```swift
var worldClocksEnabled: Bool {
    didSet { defaults.set(worldClocksEnabled, forKey: "worldClocksEnabled") }
}

var worldClocksPosition: WorldClocksPosition {
    didSet { defaults.set(worldClocksPosition.rawValue, forKey: "worldClocksPosition") }
}

var worldClocks: [WorldClock] {
    didSet {
        if let data = try? JSONEncoder().encode(worldClocks) {
            defaults.set(data, forKey: "worldClocks")
        }
    }
}

var showTimezoneAbbreviation: Bool {
    didSet { defaults.set(showTimezoneAbbreviation, forKey: "showTimezoneAbbreviation") }
}

var showDayDifference: Bool {
    didSet { defaults.set(showDayDifference, forKey: "showDayDifference") }
}
```

Add to `init()`:

```swift
self.worldClocksEnabled = defaults.bool(forKey: "worldClocksEnabled")
self.worldClocksPosition = WorldClocksPosition(rawValue: defaults.string(forKey: "worldClocksPosition") ?? "") ?? .bottom
if let data = defaults.data(forKey: "worldClocks"),
   let clocks = try? JSONDecoder().decode([WorldClock].self, from: data) {
    self.worldClocks = clocks
} else {
    self.worldClocks = []
}
self.showTimezoneAbbreviation = defaults.object(forKey: "showTimezoneAbbreviation") as? Bool ?? true
self.showDayDifference = defaults.object(forKey: "showDayDifference") as? Bool ?? true
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/AppSettings.swift MacClockTests/AppSettingsTests.swift
git commit -m "feat: add world clock settings to AppSettings"
```

---

### Task 3: Create WorldClocksView

**Files:**
- Create: `MacClock/Views/WorldClocksView.swift`

**Step 1: Create the world clocks view**

Create `MacClock/Views/WorldClocksView.swift`:

```swift
import SwiftUI

struct WorldClocksView: View {
    let settings: AppSettings
    let theme: ColorTheme

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if settings.worldClocksPosition == .bottom {
                bottomBarLayout
            } else {
                sidePanelLayout
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var bottomBarLayout: some View {
        HStack(spacing: 16) {
            ForEach(settings.worldClocks.prefix(3)) { clock in
                WorldClockItem(
                    clock: clock,
                    theme: theme,
                    use24Hour: settings.use24Hour,
                    showAbbreviation: settings.showTimezoneAbbreviation,
                    showDayDiff: settings.showDayDifference,
                    compact: true
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var sidePanelLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(settings.worldClocks.prefix(5)) { clock in
                WorldClockItem(
                    clock: clock,
                    theme: theme,
                    use24Hour: settings.use24Hour,
                    showAbbreviation: settings.showTimezoneAbbreviation,
                    showDayDiff: settings.showDayDifference,
                    compact: false
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct WorldClockItem: View {
    let clock: WorldClock
    let theme: ColorTheme
    let use24Hour: Bool
    let showAbbreviation: Bool
    let showDayDiff: Bool
    let compact: Bool

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: compact ? .center : .leading, spacing: 2) {
            Text(clock.cityName.uppercased())
                .font(.system(size: compact ? 10 : 12, weight: .medium))
                .foregroundStyle(theme.accentColor)

            HStack(spacing: 4) {
                Text(clock.currentTimeString(use24Hour: use24Hour))
                    .font(.system(size: compact ? 14 : 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.primaryColor)

                if showDayDiff && clock.dayDifferenceFromLocal != 0 {
                    Text(clock.dayDifferenceFromLocal > 0 ? "+1" : "-1")
                        .font(.system(size: compact ? 8 : 10))
                        .foregroundStyle(theme.accentColor.opacity(0.7))
                }
            }

            if showAbbreviation && !compact {
                Text(clock.timezoneAbbreviation)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.accentColor.opacity(0.6))
            }
        }
        .frame(minWidth: compact ? 70 : 100)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

#Preview("Bottom Bar") {
    let settings = AppSettings()
    settings.worldClocks = [
        WorldClock(id: UUID(), cityName: "New York", timezoneIdentifier: "America/New_York"),
        WorldClock(id: UUID(), cityName: "London", timezoneIdentifier: "Europe/London"),
        WorldClock(id: UUID(), cityName: "Tokyo", timezoneIdentifier: "Asia/Tokyo")
    ]
    settings.worldClocksPosition = .bottom
    return WorldClocksView(settings: settings, theme: .classicWhite)
        .background(.black)
}

#Preview("Side Panel") {
    let settings = AppSettings()
    settings.worldClocks = [
        WorldClock(id: UUID(), cityName: "New York", timezoneIdentifier: "America/New_York"),
        WorldClock(id: UUID(), cityName: "London", timezoneIdentifier: "Europe/London"),
        WorldClock(id: UUID(), cityName: "Tokyo", timezoneIdentifier: "Asia/Tokyo")
    ]
    settings.worldClocksPosition = .side
    return WorldClocksView(settings: settings, theme: .classicWhite)
        .background(.black)
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/WorldClocksView.swift
git commit -m "feat: add WorldClocksView with bottom bar and side panel layouts"
```

---

### Task 4: Create City Search Service

**Files:**
- Create: `MacClock/Services/CitySearchService.swift`

**Step 1: Create the city search service**

Create `MacClock/Services/CitySearchService.swift`:

```swift
import Foundation

struct CitySearchResult: Identifiable {
    let id = UUID()
    let cityName: String
    let countryName: String
    let timezoneIdentifier: String

    var displayName: String {
        "\(cityName), \(countryName)"
    }
}

actor CitySearchService {
    // Common cities with their timezones
    private let cities: [CitySearchResult] = [
        CitySearchResult(cityName: "New York", countryName: "USA", timezoneIdentifier: "America/New_York"),
        CitySearchResult(cityName: "Los Angeles", countryName: "USA", timezoneIdentifier: "America/Los_Angeles"),
        CitySearchResult(cityName: "Chicago", countryName: "USA", timezoneIdentifier: "America/Chicago"),
        CitySearchResult(cityName: "London", countryName: "UK", timezoneIdentifier: "Europe/London"),
        CitySearchResult(cityName: "Paris", countryName: "France", timezoneIdentifier: "Europe/Paris"),
        CitySearchResult(cityName: "Berlin", countryName: "Germany", timezoneIdentifier: "Europe/Berlin"),
        CitySearchResult(cityName: "Tokyo", countryName: "Japan", timezoneIdentifier: "Asia/Tokyo"),
        CitySearchResult(cityName: "Sydney", countryName: "Australia", timezoneIdentifier: "Australia/Sydney"),
        CitySearchResult(cityName: "Dubai", countryName: "UAE", timezoneIdentifier: "Asia/Dubai"),
        CitySearchResult(cityName: "Singapore", countryName: "Singapore", timezoneIdentifier: "Asia/Singapore"),
        CitySearchResult(cityName: "Hong Kong", countryName: "China", timezoneIdentifier: "Asia/Hong_Kong"),
        CitySearchResult(cityName: "Mumbai", countryName: "India", timezoneIdentifier: "Asia/Kolkata"),
        CitySearchResult(cityName: "Moscow", countryName: "Russia", timezoneIdentifier: "Europe/Moscow"),
        CitySearchResult(cityName: "São Paulo", countryName: "Brazil", timezoneIdentifier: "America/Sao_Paulo"),
        CitySearchResult(cityName: "Toronto", countryName: "Canada", timezoneIdentifier: "America/Toronto"),
        CitySearchResult(cityName: "Vancouver", countryName: "Canada", timezoneIdentifier: "America/Vancouver"),
        CitySearchResult(cityName: "Amsterdam", countryName: "Netherlands", timezoneIdentifier: "Europe/Amsterdam"),
        CitySearchResult(cityName: "Stockholm", countryName: "Sweden", timezoneIdentifier: "Europe/Stockholm"),
        CitySearchResult(cityName: "Seoul", countryName: "South Korea", timezoneIdentifier: "Asia/Seoul"),
        CitySearchResult(cityName: "Bangkok", countryName: "Thailand", timezoneIdentifier: "Asia/Bangkok"),
        CitySearchResult(cityName: "Cairo", countryName: "Egypt", timezoneIdentifier: "Africa/Cairo"),
        CitySearchResult(cityName: "Johannesburg", countryName: "South Africa", timezoneIdentifier: "Africa/Johannesburg"),
        CitySearchResult(cityName: "Auckland", countryName: "New Zealand", timezoneIdentifier: "Pacific/Auckland"),
        CitySearchResult(cityName: "Denver", countryName: "USA", timezoneIdentifier: "America/Denver"),
        CitySearchResult(cityName: "Phoenix", countryName: "USA", timezoneIdentifier: "America/Phoenix"),
    ]

    func search(query: String) -> [CitySearchResult] {
        guard !query.isEmpty else { return [] }
        let lowercased = query.lowercased()
        return cities.filter {
            $0.cityName.lowercased().contains(lowercased) ||
            $0.countryName.lowercased().contains(lowercased)
        }
    }

    func allCities() -> [CitySearchResult] {
        cities
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Services/CitySearchService.swift
git commit -m "feat: add CitySearchService with common cities"
```

---

### Task 5: Add World Clocks Settings UI

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add Information section with world clocks settings**

In `MacClock/Views/SettingsView.swift`, add new section before "System":

```swift
Section("Information") {
    Toggle("World Clocks", isOn: $settings.worldClocksEnabled)

    if settings.worldClocksEnabled {
        Picker("Position", selection: $settings.worldClocksPosition) {
            ForEach(WorldClocksPosition.allCases, id: \.self) { pos in
                Text(pos.rawValue).tag(pos)
            }
        }

        Toggle("Show Timezone", isOn: $settings.showTimezoneAbbreviation)
        Toggle("Show Day Difference", isOn: $settings.showDayDifference)

        // City list
        ForEach(settings.worldClocks) { clock in
            HStack {
                Text(clock.cityName)
                Spacer()
                Text(clock.timezoneAbbreviation)
                    .foregroundStyle(.secondary)
                Button {
                    settings.worldClocks.removeAll { $0.id == clock.id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }

        if settings.worldClocks.count < 5 {
            Button {
                showCityPicker = true
            } label: {
                Label("Add City", systemImage: "plus.circle.fill")
            }
        }
    }
}
```

Add state and sheet for city picker at the top of SettingsView:

```swift
@State private var showCityPicker = false
@State private var citySearchText = ""
@State private var citySearchService = CitySearchService()
```

Add sheet modifier:

```swift
.sheet(isPresented: $showCityPicker) {
    CityPickerSheet(
        settings: settings,
        searchService: citySearchService,
        isPresented: $showCityPicker
    )
}
```

Create CityPickerSheet in the same file or separate:

```swift
struct CityPickerSheet: View {
    let settings: AppSettings
    let searchService: CitySearchService
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var searchResults: [CitySearchResult] = []

    var body: some View {
        VStack {
            TextField("Search city...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: searchText) { _, newValue in
                    Task {
                        searchResults = await searchService.search(query: newValue)
                    }
                }

            List(searchResults) { result in
                Button {
                    let clock = WorldClock(
                        id: UUID(),
                        cityName: result.cityName,
                        timezoneIdentifier: result.timezoneIdentifier
                    )
                    settings.worldClocks.append(clock)
                    isPresented = false
                } label: {
                    HStack {
                        Text(result.displayName)
                        Spacer()
                        Text(TimeZone(identifier: result.timezoneIdentifier)?.abbreviation() ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Cancel") {
                isPresented = false
            }
            .padding()
        }
        .frame(width: 300, height: 400)
        .task {
            searchResults = await searchService.allCities()
        }
    }
}
```

Update frame height:

```swift
.frame(width: 350, height: 700)
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: World clocks settings appear

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat: add world clocks settings UI with city picker"
```

---

### Task 6: Integrate World Clocks into MainClockView

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add world clocks to the layout**

In MainClockView body, update the content VStack to conditionally show world clocks.

For bottom bar position, add after the clock and before the Spacer at bottom:

```swift
// World Clocks (bottom)
if settings.worldClocksEnabled && settings.worldClocksPosition == .bottom && !settings.worldClocks.isEmpty {
    WorldClocksView(settings: settings, theme: effectiveTheme)
}
```

For side panel, wrap the main content in an HStack:

Update the body to use a layout that accommodates side panel:

```swift
HStack(spacing: 0) {
    // Main content
    VStack {
        // ... existing content ...
    }
    .frame(maxWidth: .infinity)

    // World Clocks (side panel)
    if settings.worldClocksEnabled && settings.worldClocksPosition == .side && !settings.worldClocks.isEmpty {
        WorldClocksView(settings: settings, theme: effectiveTheme)
            .frame(width: 120)
    }
}
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: World clocks appear based on settings

**Step 3: Commit**

```bash
git add MacClock/MacClockApp.swift
git commit -m "feat: integrate world clocks into MainClockView"
```

---

### Task 7: Create NewsService for RSS Feeds

**Files:**
- Create: `MacClock/Services/NewsService.swift`
- Create: `MacClock/Models/NewsItem.swift`
- Test: `MacClockTests/NewsServiceTests.swift`

**Step 1: Create NewsItem model**

Create `MacClock/Models/NewsItem.swift`:

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

    static let builtInFeeds: [NewsFeed] = [
        NewsFeed(id: UUID(), name: "BBC World", url: "https://feeds.bbci.co.uk/news/world/rss.xml", isEnabled: true),
        NewsFeed(id: UUID(), name: "Reuters", url: "https://www.reutersagency.com/feed/?best-regions=europe&post_type=best", isEnabled: false),
        NewsFeed(id: UUID(), name: "NPR News", url: "https://feeds.npr.org/1001/rss.xml", isEnabled: false),
        NewsFeed(id: UUID(), name: "The Guardian", url: "https://www.theguardian.com/world/rss", isEnabled: false),
    ]
}
```

**Step 2: Create NewsService**

Create `MacClock/Services/NewsService.swift`:

```swift
import Foundation

actor NewsService: NSObject, XMLParserDelegate {
    private var newsItems: [NewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentSource = ""
    private var isInItem = false

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
            let (data, _) = try await URLSession.shared.data(from: url)
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
```

**Step 3: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add MacClock/Models/NewsItem.swift MacClock/Services/NewsService.swift
git commit -m "feat: add NewsService with RSS feed parsing"
```

---

### Task 8: Add News Ticker Settings to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`

**Step 1: Add news ticker settings**

Add enum after `WorldClocksPosition`:

```swift
enum NewsTickerStyle: String, CaseIterable {
    case scrolling = "Scrolling"
    case rotating = "Rotating"
}
```

Add properties:

```swift
var newsTickerEnabled: Bool {
    didSet { defaults.set(newsTickerEnabled, forKey: "newsTickerEnabled") }
}

var newsTickerStyle: NewsTickerStyle {
    didSet { defaults.set(newsTickerStyle.rawValue, forKey: "newsTickerStyle") }
}

var newsFeeds: [NewsFeed] {
    didSet {
        if let data = try? JSONEncoder().encode(newsFeeds) {
            defaults.set(data, forKey: "newsFeeds")
        }
    }
}

var newsRefreshInterval: Double {
    didSet { defaults.set(newsRefreshInterval, forKey: "newsRefreshInterval") }
}

var newsScrollSpeed: Double {
    didSet { defaults.set(newsScrollSpeed, forKey: "newsScrollSpeed") }
}

var newsRotateInterval: Double {
    didSet { defaults.set(newsRotateInterval, forKey: "newsRotateInterval") }
}
```

Add to `init()`:

```swift
self.newsTickerEnabled = defaults.bool(forKey: "newsTickerEnabled")
self.newsTickerStyle = NewsTickerStyle(rawValue: defaults.string(forKey: "newsTickerStyle") ?? "") ?? .scrolling
if let data = defaults.data(forKey: "newsFeeds"),
   let feeds = try? JSONDecoder().decode([NewsFeed].self, from: data) {
    self.newsFeeds = feeds
} else {
    self.newsFeeds = NewsFeed.builtInFeeds
}
self.newsRefreshInterval = defaults.object(forKey: "newsRefreshInterval") as? Double ?? 15.0
self.newsScrollSpeed = defaults.object(forKey: "newsScrollSpeed") as? Double ?? 50.0
self.newsRotateInterval = defaults.object(forKey: "newsRotateInterval") as? Double ?? 10.0
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Models/AppSettings.swift
git commit -m "feat: add news ticker settings to AppSettings"
```

---

### Task 9: Create NewsTickerView

**Files:**
- Create: `MacClock/Views/NewsTickerView.swift`

**Step 1: Create the news ticker view**

Create `MacClock/Views/NewsTickerView.swift`:

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
    }

    private var scrollingTicker: some View {
        GeometryReader { geometry in
            let text = newsItems.map { $0.displayTitle }.joined(separator: "  •  ")

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(theme.primaryColor)
                .lineLimit(1)
                .fixedSize()
                .offset(x: scrollOffset)
                .onAppear {
                    startScrolling(containerWidth: geometry.size.width)
                }
                .onTapGesture {
                    if let item = newsItems.first, let url = item.link {
                        NSWorkspace.shared.open(url)
                    }
                }
        }
        .clipped()
    }

    private var rotatingTicker: some View {
        Group {
            if !newsItems.isEmpty {
                let item = newsItems[currentIndex % newsItems.count]
                Text(item.displayTitle)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .opacity(opacity)
                    .onAppear {
                        startRotating()
                    }
                    .onTapGesture {
                        if let url = item.link {
                            NSWorkspace.shared.open(url)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private func startScrolling(containerWidth: CGFloat) {
        scrollOffset = containerWidth

        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            scrollOffset -= settings.newsScrollSpeed * 0.03
            if scrollOffset < -2000 {
                scrollOffset = containerWidth
            }
        }
    }

    private func startRotating() {
        Timer.scheduledTimer(withTimeInterval: settings.newsRotateInterval, repeats: true) { _ in
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

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/NewsTickerView.swift
git commit -m "feat: add NewsTickerView with scrolling and rotating modes"
```

---

### Task 10: Add News Ticker Settings UI and Integration

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add news ticker settings to Information section**

In SettingsView, add to the Information section after world clocks:

```swift
Divider()

Toggle("News Ticker", isOn: $settings.newsTickerEnabled)

if settings.newsTickerEnabled {
    Picker("Style", selection: $settings.newsTickerStyle) {
        ForEach(NewsTickerStyle.allCases, id: \.self) { style in
            Text(style.rawValue).tag(style)
        }
    }

    if settings.newsTickerStyle == .scrolling {
        VStack(alignment: .leading) {
            Text("Scroll Speed: \(Int(settings.newsScrollSpeed))")
            Slider(value: $settings.newsScrollSpeed, in: 20...100, step: 10)
        }
    } else {
        VStack(alignment: .leading) {
            Text("Rotate Every: \(Int(settings.newsRotateInterval))s")
            Slider(value: $settings.newsRotateInterval, in: 5...30, step: 5)
        }
    }

    Text("News Sources")
        .font(.headline)
        .padding(.top, 8)

    ForEach($settings.newsFeeds) { $feed in
        Toggle(feed.name, isOn: $feed.isEnabled)
    }
}
```

**Step 2: Integrate news ticker into MainClockView**

In MainClockView, add state for news:

```swift
@State private var newsService = NewsService()
@State private var newsItems: [NewsItem] = []
@State private var newsRefreshTimer: Timer?
```

Add news ticker at the bottom of the main ZStack, after gradient overlay:

```swift
// News Ticker
if settings.newsTickerEnabled && !newsItems.isEmpty {
    VStack {
        Spacer()
        NewsTickerView(settings: settings, theme: effectiveTheme, newsItems: newsItems)
    }
}
```

Add news loading in onAppear:

```swift
if settings.newsTickerEnabled {
    Task { await loadNews() }
    newsRefreshTimer = Timer.scheduledTimer(withTimeInterval: settings.newsRefreshInterval * 60, repeats: true) { _ in
        Task { await loadNews() }
    }
}
```

Add loadNews method:

```swift
private func loadNews() async {
    newsItems = await newsService.fetchNews(from: settings.newsFeeds)
}
```

Add onChange for newsTickerEnabled:

```swift
.onChange(of: settings.newsTickerEnabled) { _, enabled in
    if enabled {
        Task { await loadNews() }
    }
}
```

**Step 3: Build and test**

Run: `swift build && swift run`
Expected: News ticker appears when enabled

**Step 4: Commit**

```bash
git add MacClock/Views/SettingsView.swift MacClock/MacClockApp.swift
git commit -m "feat: add news ticker settings UI and integration"
```

---

### Task 11: Create CalendarService

**Files:**
- Create: `MacClock/Services/CalendarService.swift`
- Create: `MacClock/Models/CalendarEvent.swift`

**Step 1: Create CalendarEvent model**

Create `MacClock/Models/CalendarEvent.swift`:

```swift
import Foundation
import EventKit

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarTitle: String
    let calendarColor: CGColor?
    let isAllDay: Bool

    var timeUntilStart: TimeInterval {
        startDate.timeIntervalSinceNow
    }

    var countdownString: String {
        let interval = timeUntilStart
        if interval < 0 { return "Now" }

        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "in \(minutes) min"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours < 24 {
            return remainingMinutes > 0 ? "in \(hours)h \(remainingMinutes)m" : "in \(hours)h"
        }

        return "Tomorrow"
    }

    init(from event: EKEvent) {
        self.id = event.eventIdentifier ?? UUID().uuidString
        self.title = event.title ?? "Untitled"
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.calendarTitle = event.calendar?.title ?? ""
        self.calendarColor = event.calendar?.cgColor
        self.isAllDay = event.isAllDay
    }
}
```

**Step 2: Create CalendarService**

Create `MacClock/Services/CalendarService.swift`:

```swift
import Foundation
import EventKit

@Observable
final class CalendarService {
    private let eventStore = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private(set) var availableCalendars: [EKCalendar] = []

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess || authorizationStatus == .authorized {
            loadCalendars()
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                authorizationStatus = granted ? .fullAccess : .denied
                if granted {
                    loadCalendars()
                }
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    private func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
    }

    func fetchTodayEvents(from calendarIDs: [String]) -> [CalendarEvent] {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else {
            return []
        }

        let calendars = availableCalendars.filter { calendarIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)
        return events
            .map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchNextEvent(from calendarIDs: [String]) -> CalendarEvent? {
        let now = Date()
        return fetchTodayEvents(from: calendarIDs)
            .first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }
    }
}
```

**Step 3: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add MacClock/Models/CalendarEvent.swift MacClock/Services/CalendarService.swift
git commit -m "feat: add CalendarService with EventKit integration"
```

---

### Task 12: Add Calendar Settings to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`

**Step 1: Add calendar settings**

Add properties:

```swift
var calendarEnabled: Bool {
    didSet { defaults.set(calendarEnabled, forKey: "calendarEnabled") }
}

var calendarShowCountdown: Bool {
    didSet { defaults.set(calendarShowCountdown, forKey: "calendarShowCountdown") }
}

var calendarShowAgenda: Bool {
    didSet { defaults.set(calendarShowAgenda, forKey: "calendarShowAgenda") }
}

var calendarAgendaPosition: WorldClocksPosition {
    didSet { defaults.set(calendarAgendaPosition.rawValue, forKey: "calendarAgendaPosition") }
}

var selectedCalendarIDs: [String] {
    didSet { defaults.set(selectedCalendarIDs, forKey: "selectedCalendarIDs") }
}
```

Add to `init()`:

```swift
self.calendarEnabled = defaults.bool(forKey: "calendarEnabled")
self.calendarShowCountdown = defaults.object(forKey: "calendarShowCountdown") as? Bool ?? true
self.calendarShowAgenda = defaults.bool(forKey: "calendarShowAgenda")
self.calendarAgendaPosition = WorldClocksPosition(rawValue: defaults.string(forKey: "calendarAgendaPosition") ?? "") ?? .side
self.selectedCalendarIDs = defaults.stringArray(forKey: "selectedCalendarIDs") ?? []
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Models/AppSettings.swift
git commit -m "feat: add calendar settings to AppSettings"
```

---

### Task 13: Create CalendarViews

**Files:**
- Create: `MacClock/Views/CalendarViews.swift`

**Step 1: Create calendar views**

Create `MacClock/Views/CalendarViews.swift`:

```swift
import SwiftUI

struct CalendarCountdownView: View {
    let event: CalendarEvent?
    let theme: ColorTheme

    var body: some View {
        if let event = event {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accentColor)

                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)

                Text(event.countdownString)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.accentColor)
            }
        }
    }
}

struct CalendarAgendaView: View {
    let events: [CalendarEvent]
    let theme: ColorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.accentColor)

            if events.isEmpty {
                Text("No events")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.accentColor.opacity(0.6))
            } else {
                ForEach(events.prefix(6)) { event in
                    CalendarAgendaItem(event: event, theme: theme)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct CalendarAgendaItem: View {
    let event: CalendarEvent
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator
            if let color = event.calendarColor {
                Circle()
                    .fill(Color(cgColor: color))
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)

                Text(formatTime(event))
                    .font(.system(size: 10))
                    .foregroundStyle(theme.accentColor)
            }
        }
    }

    private func formatTime(_ event: CalendarEvent) -> String {
        if event.isAllDay { return "All day" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
}

#Preview {
    VStack {
        CalendarCountdownView(
            event: nil,
            theme: .classicWhite
        )

        CalendarAgendaView(
            events: [],
            theme: .classicWhite
        )
    }
    .padding()
    .background(.black)
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/CalendarViews.swift
git commit -m "feat: add CalendarCountdownView and CalendarAgendaView"
```

---

### Task 14: Add Calendar Settings UI and Integration

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add calendar settings to Information section**

In SettingsView, add to the Information section:

```swift
Divider()

Toggle("Calendar", isOn: $settings.calendarEnabled)

if settings.calendarEnabled {
    if calendarService.authorizationStatus != .fullAccess && calendarService.authorizationStatus != .authorized {
        Button("Grant Calendar Access") {
            Task { await calendarService.requestAccess() }
        }
    } else {
        Toggle("Show Next Event", isOn: $settings.calendarShowCountdown)
        Toggle("Show Agenda Panel", isOn: $settings.calendarShowAgenda)

        if settings.calendarShowAgenda {
            Picker("Panel Position", selection: $settings.calendarAgendaPosition) {
                ForEach(WorldClocksPosition.allCases, id: \.self) { pos in
                    Text(pos.rawValue).tag(pos)
                }
            }
        }

        Text("Calendars")
            .font(.headline)
            .padding(.top, 8)

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
```

Add calendarService state to SettingsView:

```swift
@State private var calendarService = CalendarService()
```

**Step 2: Integrate calendar into MainClockView**

Add state:

```swift
@State private var calendarService = CalendarService()
@State private var nextEvent: CalendarEvent?
@State private var todayEvents: [CalendarEvent] = []
@State private var calendarRefreshTimer: Timer?
```

Add countdown to top bar (after weather):

```swift
if settings.calendarEnabled && settings.calendarShowCountdown {
    CalendarCountdownView(event: nextEvent, theme: effectiveTheme)
}
```

Add agenda panel in HStack with main content (similar to world clocks side panel):

```swift
if settings.calendarEnabled && settings.calendarShowAgenda && settings.calendarAgendaPosition == .side {
    CalendarAgendaView(events: todayEvents, theme: effectiveTheme)
        .frame(width: 150)
}
```

Add calendar loading:

```swift
private func loadCalendarEvents() {
    nextEvent = calendarService.fetchNextEvent(from: settings.selectedCalendarIDs)
    todayEvents = calendarService.fetchTodayEvents(from: settings.selectedCalendarIDs)
}
```

In onAppear:

```swift
if settings.calendarEnabled {
    loadCalendarEvents()
    calendarRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
        loadCalendarEvents()
    }
}
```

**Step 3: Build and test**

Run: `swift build && swift run`
Expected: Calendar features work when enabled

**Step 4: Commit**

```bash
git add MacClock/Views/SettingsView.swift MacClock/MacClockApp.swift
git commit -m "feat: add calendar settings UI and integration"
```

---

## Phase 4: Alarms & Timers

---

### Task 15: Create Alarm Model

**Files:**
- Create: `MacClock/Models/Alarm.swift`
- Test: `MacClockTests/AlarmTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/AlarmTests.swift`:

```swift
import Testing
import Foundation
@testable import MacClock

@Suite("Alarm Tests")
struct AlarmTests {

    @Test("Alarm stores properties correctly")
    func alarmProperties() {
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Wake up",
            isEnabled: true,
            repeatDays: [.monday, .tuesday],
            soundName: nil,
            snoozeDuration: 5
        )
        #expect(alarm.label == "Wake up")
        #expect(alarm.isEnabled == true)
        #expect(alarm.repeatDays.contains(.monday))
        #expect(alarm.snoozeDuration == 5)
    }

    @Test("Alarm calculates next fire date")
    func nextFireDate() {
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Test",
            isEnabled: true,
            repeatDays: [],
            soundName: nil,
            snoozeDuration: 5
        )
        let nextFire = alarm.nextFireDate
        #expect(nextFire != nil)
    }

    @Test("Repeat days encode correctly")
    func repeatDaysEncoding() {
        let days: Set<Alarm.Weekday> = [.monday, .wednesday, .friday]
        #expect(days.contains(.monday))
        #expect(days.contains(.wednesday))
        #expect(days.contains(.friday))
        #expect(!days.contains(.tuesday))
    }
}
```

**Step 2: Write implementation**

Create `MacClock/Models/Alarm.swift`:

```swift
import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: DateComponents  // hour and minute
    var label: String
    var isEnabled: Bool
    var repeatDays: Set<Weekday>
    var soundName: String?  // nil = no sound (default)
    var snoozeDuration: Int  // minutes: 5, 10, or 15

    enum Weekday: Int, Codable, CaseIterable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7

        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }

        static var weekdays: Set<Weekday> {
            [.monday, .tuesday, .wednesday, .thursday, .friday]
        }

        static var weekends: Set<Weekday> {
            [.saturday, .sunday]
        }
    }

    var repeatDescription: String {
        if repeatDays.isEmpty { return "Never" }
        if repeatDays == Weekday.weekdays { return "Weekdays" }
        if repeatDays == Weekday.weekends { return "Weekends" }
        if repeatDays.count == 7 { return "Every day" }
        return repeatDays.sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName }
            .joined(separator: ", ")
    }

    var timeString: String {
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute))!
        return formatter.string(from: date)
    }

    var nextFireDate: Date? {
        guard isEnabled else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0

        // If no repeat days, find next occurrence
        if repeatDays.isEmpty {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = minute
            components.second = 0

            if let candidate = calendar.date(from: components), candidate > now {
                return candidate
            }
            // Tomorrow
            components.day! += 1
            return calendar.date(from: components)
        }

        // Find next matching weekday
        for dayOffset in 0..<8 {
            guard let candidate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = Weekday(rawValue: calendar.component(.weekday, from: candidate))

            if let weekday = weekday, repeatDays.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: candidate)
                components.hour = hour
                components.minute = minute
                components.second = 0

                if let fireDate = calendar.date(from: components), fireDate > now {
                    return fireDate
                }
            }
        }

        return nil
    }
}
```

**Step 3: Run tests**

Run: `swift test --filter AlarmTests`
Expected: PASS

**Step 4: Commit**

```bash
git add MacClock/Models/Alarm.swift MacClockTests/AlarmTests.swift
git commit -m "feat: add Alarm model with repeat days and scheduling"
```

---

### Task 16: Create AlarmService

**Files:**
- Create: `MacClock/Services/AlarmService.swift`

**Step 1: Create the alarm service**

Create `MacClock/Services/AlarmService.swift`:

```swift
import Foundation
import UserNotifications
import AVFoundation
import AppKit

@Observable
final class AlarmService {
    private(set) var activeAlarm: Alarm?
    private(set) var isAlarmFiring = false
    private var audioPlayer: AVAudioPlayer?
    private var checkTimer: Timer?
    private var snoozeUntil: Date?

    init() {
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func startMonitoring(alarms: [Alarm]) {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkAlarms(alarms)
        }
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func checkAlarms(_ alarms: [Alarm]) {
        // Don't fire if snoozed
        if let snoozeUntil = snoozeUntil, Date() < snoozeUntil {
            return
        }
        snoozeUntil = nil

        let now = Date()
        let calendar = Calendar.current

        for alarm in alarms where alarm.isEnabled {
            guard let fireDate = alarm.nextFireDate else { continue }

            // Check if fire date is within this second
            let diff = fireDate.timeIntervalSince(now)
            if diff >= 0 && diff < 1 {
                fireAlarm(alarm)
                break
            }
        }
    }

    private func fireAlarm(_ alarm: Alarm) {
        guard !isAlarmFiring else { return }

        activeAlarm = alarm
        isAlarmFiring = true

        // Send notification
        sendNotification(for: alarm)

        // Play sound if enabled
        if let soundName = alarm.soundName {
            playSound(named: soundName)
        }
    }

    private func sendNotification(for alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = alarm.label.isEmpty ? "Alarm" : alarm.label
        content.categoryIdentifier = "ALARM"

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func playSound(named name: String) {
        guard let url = getSoundURL(for: name) else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.play()
        } catch {
            print("Failed to play alarm sound: \(error)")
        }
    }

    private func getSoundURL(for name: String) -> URL? {
        // Check for system sounds
        let systemSoundPath = "/System/Library/Sounds/\(name).aiff"
        if FileManager.default.fileExists(atPath: systemSoundPath) {
            return URL(fileURLWithPath: systemSoundPath)
        }
        return nil
    }

    func dismissAlarm() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false
        activeAlarm = nil
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func snoozeAlarm() {
        guard let alarm = activeAlarm else { return }

        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false

        snoozeUntil = Date().addingTimeInterval(TimeInterval(alarm.snoozeDuration * 60))
        activeAlarm = nil
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    static var availableSounds: [String] {
        [
            "Basso",
            "Blow",
            "Bottle",
            "Frog",
            "Funk",
            "Glass",
            "Hero",
            "Morse",
            "Ping",
            "Pop",
            "Purr",
            "Sosumi",
            "Submarine",
            "Tink"
        ]
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Services/AlarmService.swift
git commit -m "feat: add AlarmService with notifications and sound playback"
```

---

### Task 17: Add Alarm Settings to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`

**Step 1: Add alarm settings**

Add properties:

```swift
var alarms: [Alarm] {
    didSet {
        if let data = try? JSONEncoder().encode(alarms) {
            defaults.set(data, forKey: "alarms")
        }
    }
}
```

Add to `init()`:

```swift
if let data = defaults.data(forKey: "alarms"),
   let loadedAlarms = try? JSONDecoder().decode([Alarm].self, from: data) {
    self.alarms = loadedAlarms
} else {
    self.alarms = []
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Models/AppSettings.swift
git commit -m "feat: add alarms array to AppSettings"
```

---

### Task 18: Create Timer and Stopwatch Models

**Files:**
- Create: `MacClock/Models/TimerState.swift`

**Step 1: Create timer and stopwatch state models**

Create `MacClock/Models/TimerState.swift`:

```swift
import Foundation

@Observable
final class CountdownTimer {
    private(set) var remainingSeconds: Int = 0
    private(set) var isRunning = false
    private(set) var isComplete = false
    private var timer: Timer?

    var displayTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start(minutes: Int) {
        remainingSeconds = minutes * 60
        isRunning = true
        isComplete = false

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func start(seconds: Int) {
        remainingSeconds = seconds
        isRunning = true
        isComplete = false

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            complete()
        }
    }

    private func complete() {
        isRunning = false
        isComplete = true
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard !isRunning && remainingSeconds > 0 else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func reset() {
        pause()
        remainingSeconds = 0
        isComplete = false
    }
}

@Observable
final class Stopwatch {
    private(set) var elapsedMilliseconds: Int = 0
    private(set) var isRunning = false
    private(set) var laps: [Int] = []  // lap times in milliseconds
    private var timer: Timer?
    private var startTime: Date?
    private var accumulatedTime: Int = 0

    var displayTime: String {
        let totalSeconds = elapsedMilliseconds / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let centiseconds = (elapsedMilliseconds % 1000) / 10

        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
        }
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    private func update() {
        guard let startTime = startTime else { return }
        let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
        elapsedMilliseconds = accumulatedTime + elapsed
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        accumulatedTime = elapsedMilliseconds
        timer?.invalidate()
        timer = nil
        startTime = nil
    }

    func lap() {
        guard isRunning else { return }
        let lapTime = laps.isEmpty ? elapsedMilliseconds : elapsedMilliseconds - laps.reduce(0, +)
        laps.append(lapTime)
    }

    func reset() {
        stop()
        elapsedMilliseconds = 0
        accumulatedTime = 0
        laps = []
    }

    func formatLapTime(_ milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centiseconds = (milliseconds % 1000) / 10
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Models/TimerState.swift
git commit -m "feat: add CountdownTimer and Stopwatch state models"
```

---

### Task 19: Create AlarmPanelView

**Files:**
- Create: `MacClock/Views/AlarmPanelView.swift`

**Step 1: Create the alarm panel view**

Create `MacClock/Views/AlarmPanelView.swift`:

```swift
import SwiftUI

struct AlarmPanelView: View {
    @Bindable var settings: AppSettings
    let alarmService: AlarmService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var showAddAlarm = false
    @State private var countdownTimer = CountdownTimer()
    @State private var stopwatch = Stopwatch()

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                TabButton(title: "Alarms", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "Timer", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Stopwatch", isSelected: selectedTab == 2) { selectedTab = 2 }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case 0:
                    AlarmsTabView(settings: settings, showAddAlarm: $showAddAlarm)
                case 1:
                    TimerTabView(timer: countdownTimer)
                case 2:
                    StopwatchTabView(stopwatch: stopwatch)
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 350, height: 400)
        .sheet(isPresented: $showAddAlarm) {
            AlarmEditView(settings: settings, alarm: nil, isPresented: $showAddAlarm)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct AlarmsTabView: View {
    @Bindable var settings: AppSettings
    @Binding var showAddAlarm: Bool

    var body: some View {
        VStack {
            if settings.alarms.isEmpty {
                Spacer()
                Text("No alarms")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach($settings.alarms) { $alarm in
                        AlarmRow(alarm: $alarm, onDelete: {
                            settings.alarms.removeAll { $0.id == alarm.id }
                        })
                    }
                }
            }

            Button {
                showAddAlarm = true
            } label: {
                Label("Add Alarm", systemImage: "plus.circle.fill")
            }
            .padding()
        }
    }
}

struct AlarmRow: View {
    @Binding var alarm: Alarm
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: $alarm.isEnabled)
                .labelsHidden()

            VStack(alignment: .leading) {
                Text(alarm.timeString)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                Text(alarm.label.isEmpty ? alarm.repeatDescription : alarm.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

struct TimerTabView: View {
    @Bindable var timer: CountdownTimer

    var body: some View {
        VStack(spacing: 20) {
            Text(timer.displayTime)
                .font(.system(size: 60, weight: .light, design: .monospaced))

            if !timer.isRunning && timer.remainingSeconds == 0 {
                // Presets
                HStack(spacing: 12) {
                    ForEach([5, 10, 15, 30, 60], id: \.self) { minutes in
                        Button("\(minutes)m") {
                            timer.start(minutes: minutes)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack(spacing: 20) {
                if timer.isRunning {
                    Button("Pause") { timer.pause() }
                        .buttonStyle(.borderedProminent)
                } else if timer.remainingSeconds > 0 {
                    Button("Resume") { timer.resume() }
                        .buttonStyle(.borderedProminent)
                }

                if timer.remainingSeconds > 0 || timer.isComplete {
                    Button("Reset") { timer.reset() }
                        .buttonStyle(.bordered)
                }
            }

            if timer.isComplete {
                Text("Timer Complete!")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}

struct StopwatchTabView: View {
    @Bindable var stopwatch: Stopwatch

    var body: some View {
        VStack(spacing: 20) {
            Text(stopwatch.displayTime)
                .font(.system(size: 50, weight: .light, design: .monospaced))

            HStack(spacing: 20) {
                if stopwatch.isRunning {
                    Button("Lap") { stopwatch.lap() }
                        .buttonStyle(.bordered)
                    Button("Stop") { stopwatch.stop() }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Reset") { stopwatch.reset() }
                        .buttonStyle(.bordered)
                        .disabled(stopwatch.elapsedMilliseconds == 0)
                    Button("Start") { stopwatch.start() }
                        .buttonStyle(.borderedProminent)
                }
            }

            if !stopwatch.laps.isEmpty {
                List {
                    ForEach(Array(stopwatch.laps.enumerated().reversed()), id: \.offset) { index, lap in
                        HStack {
                            Text("Lap \(index + 1)")
                            Spacer()
                            Text(stopwatch.formatLapTime(lap))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding()
    }
}

struct AlarmEditView: View {
    @Bindable var settings: AppSettings
    var alarm: Alarm?
    @Binding var isPresented: Bool

    @State private var selectedHour = 7
    @State private var selectedMinute = 0
    @State private var label = ""
    @State private var repeatDays: Set<Alarm.Weekday> = []
    @State private var soundName: String? = nil
    @State private var snoozeDuration = 5

    var body: some View {
        VStack(spacing: 16) {
            Text(alarm == nil ? "Add Alarm" : "Edit Alarm")
                .font(.headline)

            // Time picker
            HStack {
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .frame(width: 80)

                Text(":")

                Picker("Minute", selection: $selectedMinute) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .frame(width: 80)
            }

            TextField("Label (optional)", text: $label)
                .textFieldStyle(.roundedBorder)

            // Repeat days
            HStack {
                ForEach(Alarm.Weekday.allCases, id: \.self) { day in
                    Button(day.shortName.prefix(1).uppercased()) {
                        if repeatDays.contains(day) {
                            repeatDays.remove(day)
                        } else {
                            repeatDays.insert(day)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(repeatDays.contains(day) ? .accentColor : .secondary)
                }
            }

            // Sound
            Picker("Sound", selection: $soundName) {
                Text("None").tag(nil as String?)
                ForEach(AlarmService.availableSounds, id: \.self) { sound in
                    Text(sound).tag(sound as String?)
                }
            }

            // Snooze
            Picker("Snooze", selection: $snoozeDuration) {
                Text("5 min").tag(5)
                Text("10 min").tag(10)
                Text("15 min").tag(15)
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered)

                Button("Save") {
                    saveAlarm()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            if let alarm = alarm {
                selectedHour = alarm.time.hour ?? 7
                selectedMinute = alarm.time.minute ?? 0
                label = alarm.label
                repeatDays = alarm.repeatDays
                soundName = alarm.soundName
                snoozeDuration = alarm.snoozeDuration
            }
        }
    }

    private func saveAlarm() {
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: DateComponents(hour: selectedHour, minute: selectedMinute),
            label: label,
            isEnabled: true,
            repeatDays: repeatDays,
            soundName: soundName,
            snoozeDuration: snoozeDuration
        )

        if let existingIndex = settings.alarms.firstIndex(where: { $0.id == newAlarm.id }) {
            settings.alarms[existingIndex] = newAlarm
        } else {
            settings.alarms.append(newAlarm)
        }
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/AlarmPanelView.swift
git commit -m "feat: add AlarmPanelView with alarms, timer, and stopwatch tabs"
```

---

### Task 20: Create Alarm Firing Overlay

**Files:**
- Create: `MacClock/Views/AlarmFiringView.swift`

**Step 1: Create the alarm firing overlay**

Create `MacClock/Views/AlarmFiringView.swift`:

```swift
import SwiftUI

struct AlarmFiringView: View {
    let alarm: Alarm
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    let theme: ColorTheme

    @State private var pulseOpacity = 1.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Pulsing alarm icon
            Image(systemName: "alarm.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.primaryColor)
                .opacity(pulseOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        pulseOpacity = 0.4
                    }
                }

            // Time
            Text(alarm.timeString)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(theme.primaryColor)

            // Label
            if !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.title2)
                    .foregroundStyle(theme.accentColor)
            }

            Spacer()

            // Buttons
            HStack(spacing: 40) {
                Button {
                    onSnooze()
                } label: {
                    VStack {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 30))
                        Text("Snooze")
                            .font(.caption)
                    }
                    .foregroundStyle(theme.accentColor)
                }
                .buttonStyle(.plain)

                Button {
                    onDismiss()
                } label: {
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                        Text("Dismiss")
                            .font(.caption)
                    }
                    .foregroundStyle(theme.primaryColor)
                }
                .buttonStyle(.plain)
            }

            Text("Snooze for \(alarm.snoozeDuration) minutes")
                .font(.caption)
                .foregroundStyle(theme.accentColor.opacity(0.6))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}

#Preview {
    let alarm = Alarm(
        id: UUID(),
        time: DateComponents(hour: 7, minute: 30),
        label: "Wake up!",
        isEnabled: true,
        repeatDays: [],
        soundName: nil,
        snoozeDuration: 5
    )
    return AlarmFiringView(
        alarm: alarm,
        onDismiss: {},
        onSnooze: {},
        theme: .classicWhite
    )
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/AlarmFiringView.swift
git commit -m "feat: add AlarmFiringView overlay for firing alarms"
```

---

### Task 21: Integrate Alarms into MainClockView

**Files:**
- Modify: `MacClock/MacClockApp.swift`
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add alarm integration to MainClockView**

Add state:

```swift
@State private var alarmService = AlarmService()
@State private var showAlarmPanel = false
```

Add alarm monitoring in onAppear:

```swift
alarmService.startMonitoring(alarms: settings.alarms)
```

Add onChange for alarms:

```swift
.onChange(of: settings.alarms) { _, newAlarms in
    alarmService.startMonitoring(alarms: newAlarms)
}
```

Add alarm firing overlay at the end of the ZStack:

```swift
// Alarm firing overlay
if alarmService.isAlarmFiring, let alarm = alarmService.activeAlarm {
    AlarmFiringView(
        alarm: alarm,
        onDismiss: { alarmService.dismissAlarm() },
        onSnooze: { alarmService.snoozeAlarm() },
        theme: effectiveTheme
    )
}
```

Add button to open alarm panel (near settings gear):

```swift
Button {
    showAlarmPanel = true
} label: {
    Image(systemName: "alarm.fill")
        .font(.system(size: 16))
        .foregroundStyle(effectiveTheme.primaryColor.opacity(0.7))
}
.buttonStyle(.plain)
```

Add sheet:

```swift
.sheet(isPresented: $showAlarmPanel) {
    AlarmPanelView(settings: settings, alarmService: alarmService)
}
```

**Step 2: Add alarms button to SettingsView**

In SettingsView, add a section for alarms:

```swift
Section("Alarms") {
    Button("Manage Alarms, Timer & Stopwatch") {
        showAlarmPanel = true
    }
}
```

Add state and sheet similar to MainClockView.

**Step 3: Build and test**

Run: `swift build && swift run`
Expected: Alarm panel accessible, alarms fire when scheduled

**Step 4: Commit**

```bash
git add MacClock/MacClockApp.swift MacClock/Views/SettingsView.swift
git commit -m "feat: integrate alarm system into MainClockView"
```

---

### Task 22: Final Integration Test

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 2: Build release and test manually**

Run: `./build-app.sh && open MacClock.app`

Test the following:
- [ ] World clocks display in bottom bar
- [ ] World clocks display in side panel
- [ ] City search and add works
- [ ] News ticker scrolls/rotates
- [ ] News feeds can be enabled/disabled
- [ ] Calendar countdown shows next event
- [ ] Calendar agenda panel shows today's events
- [ ] Alarm can be created
- [ ] Alarm fires with notification
- [ ] Alarm sound plays (when enabled)
- [ ] Snooze and dismiss work
- [ ] Timer countdown works
- [ ] Stopwatch with laps works

**Step 3: Commit final**

```bash
git add -A
git commit -m "chore: phase 3 & 4 complete - information display and alarms"
```

---

## Summary

**Phase 3 (Tasks 1-14): Information Display**
- WorldClock model and WorldClocksView (bottom bar / side panel)
- CitySearchService with common cities
- NewsService with RSS parsing
- NewsTickerView (scrolling / rotating modes)
- CalendarService with EventKit integration
- CalendarViews (countdown + agenda panel)
- All settings UI integrated

**Phase 4 (Tasks 15-22): Alarms & Timers**
- Alarm model with repeat days and scheduling
- AlarmService with UserNotifications and sound playback
- CountdownTimer and Stopwatch state models
- AlarmPanelView with three tabs
- AlarmFiringView overlay
- Full integration into MainClockView
