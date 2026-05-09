import SwiftUI

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
                LabeledContent("Max Age") {
                    Picker("", selection: $settings.newsMaxAgeDays) {
                        Text("1 day").tag(1)
                        Text("3 days").tag(3)
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                        Text("No limit").tag(0)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }

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
