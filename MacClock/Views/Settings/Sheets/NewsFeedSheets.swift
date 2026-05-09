import SwiftUI
import AppKit

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
