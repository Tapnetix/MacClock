# News Tab & Feed Discovery Design

## Overview

Split the News functionality from the Extras tab into its own dedicated tab, add the ability to manage multiple custom RSS feeds with search/discovery, and add navigation controls to the news ticker.

## Goals

1. Dedicated News tab in Settings for better organization
2. Support multiple user-defined RSS feeds alongside built-in presets
3. Feed discovery via website URL autodiscovery and keyword search
4. News ticker navigation to revisit previous headlines

## UI Design

### News Tab in Settings

```
[News Tab Icon: newspaper.fill]

┌─ News Ticker ─────────────────────────┐
│ ☑ Enable News Ticker                  │
│ Style: [Scrolling ▾]                  │
│ Speed/Interval: ───●─── 50            │
└───────────────────────────────────────┘

┌─ Your Feeds ──────────────────────────┐
│ [Search feeds or enter URL...]  [+]   │
│                                       │
│ ☑ BBC World              [Built-in]   │
│ ☐ Reuters                [Built-in]   │
│ ☑ TechCrunch            [Custom] [×]  │
│ ☑ Hacker News           [Custom] [×]  │
│                                       │
│ [+ Add Feed Manually]                 │
└───────────────────────────────────────┘
```

**Behavior:**
- Built-in feeds: can enable/disable, cannot delete
- Custom feeds: can enable/disable AND delete
- Search field triggers discovery flow
- "Add Feed Manually" opens direct URL entry dialog

### Search & Discovery Flow

**Input Detection:**
- Contains "." and no spaces → treated as URL
- Otherwise → treated as keyword search

**URL Discovery (website URL entered):**
1. Fetch the webpage HTML
2. Parse `<link rel="alternate" type="application/rss+xml">` tags
3. If found → show list of discovered feeds
4. If not found → try common paths (`/feed`, `/rss`, `/atom.xml`, `/feed.xml`)
5. If still nothing → show error "No RSS feeds found on this site"

**Keyword Search:**
1. Call Feedly public API: `https://cloud.feedly.com/v3/search/feeds?query={keywords}`
2. Display results with title, website, subscriber count
3. User selects feeds to add

### Search Results Sheet

```
┌─ Search Results ──────────────────────┐
│ Found 3 feeds for "tech news"         │
│                                       │
│ ┌─────────────────────────────────┐   │
│ │ TechCrunch                      │   │
│ │ techcrunch.com • 2.1M readers   │   │
│ │                           [Add] │   │
│ └─────────────────────────────────┘   │
│ ┌─────────────────────────────────┐   │
│ │ Ars Technica                    │   │
│ │ arstechnica.com • 890K readers  │   │
│ │                           [Add] │   │
│ └─────────────────────────────────┘   │
│                                       │
│               [Done]                  │
└───────────────────────────────────────┘
```

### News Ticker Navigation

On the main clock view, the news ticker displays hover-to-reveal navigation:

```
     [visible on hover]        [visible on hover]
            ◀  The Guardian: Climate summit reaches...  ▶
```

**Behavior:**
- Navigation arrows appear when mouse hovers over ticker area
- **◀ Previous**: Show the previous headline
- **▶ Next**: Skip to the next headline
- Clicking headline opens article in default browser
- After manual navigation, auto-rotation pauses for 5 seconds then resumes

**Scrolling Style:**
- Arrows jump to prev/next item
- Current scroll smoothly transitions to new item

**Rotating Style:**
- Arrows immediately switch with fade transition
- Rotation timer resets

## Data Model

### Updated NewsFeed

```swift
struct NewsFeed: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var isEnabled: Bool
    var isBuiltIn: Bool  // true for preset feeds, false for user-added

    static let builtInFeeds: [NewsFeed] = [
        NewsFeed(id: UUID(), name: "BBC World", url: "...", isEnabled: true, isBuiltIn: true),
        NewsFeed(id: UUID(), name: "Reuters", url: "...", isEnabled: false, isBuiltIn: true),
        NewsFeed(id: UUID(), name: "NPR News", url: "...", isEnabled: false, isBuiltIn: true),
        NewsFeed(id: UUID(), name: "The Guardian", url: "...", isEnabled: false, isBuiltIn: true),
    ]
}
```

### DiscoveredFeed (for search results)

```swift
struct DiscoveredFeed: Identifiable {
    let id = UUID()
    let title: String
    let feedURL: String
    let websiteURL: String?
    let description: String?
    let subscriberCount: Int?
}
```

## Services

### FeedDiscoveryService

```swift
actor FeedDiscoveryService {
    /// Search for feeds by keywords using Feedly API
    func searchFeeds(query: String) async throws -> [DiscoveredFeed]

    /// Discover RSS feeds from a website URL via autodiscovery
    func discoverFeeds(from websiteURL: URL) async throws -> [DiscoveredFeed]

    /// Validate that a URL is a working RSS feed
    func validateFeed(url: URL) async throws -> DiscoveredFeed
}
```

**Feedly API endpoint:**
```
GET https://cloud.feedly.com/v3/search/feeds?query={keywords}&count=10
```

Response includes: `title`, `website`, `feedId` (contains URL), `subscribers`

## Settings Tab Changes

### Current Tabs
1. General
2. Appearance
3. Window
4. Location
5. World Clocks
6. Extras (News + Calendar + Alarms)

### New Tabs
1. General
2. Appearance
3. Window
4. Location
5. World Clocks
6. **News** (split out)
7. Extras (Calendar + Alarms only)

## Migration

When loading settings:
- Existing `newsFeeds` without `isBuiltIn` field → assume built-in if URL matches preset, otherwise custom
- Or: reset to default built-in feeds + mark any extras as custom

## Implementation Tasks

1. Update `NewsFeed` model with `isBuiltIn` field
2. Create `FeedDiscoveryService` with search and autodiscovery
3. Create `DiscoveredFeed` model
4. Add new `SettingsTab.news` case with icon
5. Create `NewsTabView` for Settings
6. Create `FeedSearchSheet` for search results
7. Create `AddFeedManuallySheet` for direct URL entry
8. Update `NewsTickerView` with hover navigation
9. Add navigation state management (current index, history)
10. Update `ExtrasTabView` to remove News section
11. Write tests for FeedDiscoveryService
