import SwiftUI

// MARK: - iCal Feed Row

struct ICalFeedRow: View {
    @Binding var feed: ICalFeed
    let onTest: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: feed.colorHex))
                .frame(width: 10, height: 10)

            Toggle("", isOn: $feed.isEnabled)
                .labelsHidden()
                .toggleStyle(.checkbox)

            Text(feed.name)

            Spacer()

            Button {
                onTest()
            } label: {
                Image(systemName: "arrow.clockwise.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Test connection")

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

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

// MARK: - Add iCal Feed Sheet

struct AddICalFeedSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (ICalFeed) -> Void

    @State private var name = ""
    @State private var url = ""
    @State private var selectedColorHex = ICalFeed.colorPresets[4].hex // Blue default

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Online Calendar")
                .font(.headline)

            TextField("Calendar Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("iCal URL (https://...)", text: $url)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Color:")
                    .foregroundStyle(.secondary)

                ForEach(ICalFeed.colorPresets) { preset in
                    Button {
                        selectedColorHex = preset.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.hex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColorHex == preset.hex ? 2 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("To find your Google Calendar URL: Calendar Settings -> [calendar] -> \"Secret address in iCal format\"")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Add") {
                    let feed = ICalFeed(
                        id: UUID(),
                        name: name,
                        url: url,
                        isEnabled: true,
                        colorHex: selectedColorHex
                    )
                    onAdd(feed)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || url.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - Edit iCal Feed Sheet

struct EditICalFeedSheet: View {
    let feed: ICalFeed
    @Binding var isPresented: Bool
    let onSave: (ICalFeed) -> Void

    @State private var name: String
    @State private var url: String
    @State private var selectedColorHex: String

    init(feed: ICalFeed, isPresented: Binding<Bool>, onSave: @escaping (ICalFeed) -> Void) {
        self.feed = feed
        self._isPresented = isPresented
        self.onSave = onSave
        self._name = State(initialValue: feed.name)
        self._url = State(initialValue: feed.url)
        self._selectedColorHex = State(initialValue: feed.colorHex)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Online Calendar")
                .font(.headline)

            TextField("Calendar Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("iCal URL (https://...)", text: $url)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Color:")
                    .foregroundStyle(.secondary)

                ForEach(ICalFeed.colorPresets) { preset in
                    Button {
                        selectedColorHex = preset.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.hex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColorHex == preset.hex ? 2 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    let updatedFeed = ICalFeed(
                        id: feed.id,
                        name: name,
                        url: url,
                        isEnabled: feed.isEnabled,
                        colorHex: selectedColorHex
                    )
                    onSave(updatedFeed)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || url.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - Test iCal Feed Sheet

struct TestICalFeedSheet: View {
    let feed: ICalFeed
    @Binding var isPresented: Bool

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var allEvents: [CalendarEvent] = []
    @State private var todayEvents: [CalendarEvent] = []
    @State private var rawContentPreview: String = ""

    private let iCalService = ICalService()

    var body: some View {
        VStack(spacing: 16) {
            Text("Test Connection: \(feed.name)")
                .font(.headline)

            if isLoading {
                ProgressView("Fetching calendar...")
                    .padding()
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text("Connection Failed")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if !rawContentPreview.isEmpty {
                        Divider()
                        Text("Response preview:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ScrollView {
                            Text(rawContentPreview)
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 100)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("Connection Successful")
                        .font(.headline)

                    Divider()

                    HStack {
                        VStack {
                            Text("\(allEvents.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Total Events")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text("\(todayEvents.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(todayEvents.isEmpty ? .red : .primary)
                            Text("Today's Events")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if todayEvents.isEmpty && !allEvents.isEmpty {
                        Text("No events scheduled for today, but calendar has events on other days.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }

                    if !todayEvents.isEmpty {
                        Divider()
                        Text("Today's Events:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(todayEvents.prefix(10)) { event in
                                    HStack {
                                        Text(formatTime(event.startDate))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .leading)
                                        Text(event.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                                if todayEvents.count > 10 {
                                    Text("... and \(todayEvents.count - 10) more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                    } else if !allEvents.isEmpty {
                        Divider()
                        Text("Upcoming Events:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(allEvents.sorted { $0.startDate < $1.startDate }.prefix(5)) { event in
                                    HStack {
                                        Text(formatDate(event.startDate))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 80, alignment: .leading)
                                        Text(event.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 100)
                    }
                }
            }

            Divider()

            Text("Host: \(URL(string: feed.url)?.host ?? "Unknown")")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Button("Close") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400)
        .task {
            await testConnection()
        }
    }

    private func testConnection() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: feed.url) else {
            errorMessage = "Invalid URL format"
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    errorMessage = "HTTP Error: \(httpResponse.statusCode)"
                    if let preview = String(data: data.prefix(500), encoding: .utf8) {
                        rawContentPreview = preview
                    }
                    isLoading = false
                    return
                }
            }

            guard let content = String(data: data, encoding: .utf8) else {
                errorMessage = "Could not decode response as text"
                isLoading = false
                return
            }

            // Check if it looks like ICS content
            if !content.contains("BEGIN:VCALENDAR") {
                errorMessage = "Response is not valid iCal format (missing BEGIN:VCALENDAR)"
                rawContentPreview = String(content.prefix(500))
                isLoading = false
                return
            }

            // Parse events
            let events = iCalService.parseICS(content, feedName: feed.name, colorHex: feed.colorHex)
            allEvents = events

            // Filter today's events
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
            todayEvents = events.filter { $0.startDate >= today && $0.startDate < tomorrow }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
