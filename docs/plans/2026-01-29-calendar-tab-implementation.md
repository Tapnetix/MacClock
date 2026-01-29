# Calendar Tab & iCal Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix native calendar access, split Calendar into its own Settings tab, and add iCal URL support for external calendars.

**Architecture:** Add NSCalendarsUsageDescription to fix permissions, create ICalFeed model and ICalService for parsing ICS feeds, create new Calendar tab with local and online calendar management, update CalendarService to merge events from all sources.

**Tech Stack:** Swift, SwiftUI, EventKit (local calendars), URLSession (iCal fetching), ICS parsing

---

### Task 1: Fix Calendar Access - Add Usage Description

**Files:**
- Modify: `MacClock/Info.plist`

**Step 1: Add calendar usage description to Info.plist**

Edit `MacClock/Info.plist` to add the calendar permission string:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ATSApplicationFontsPath</key>
    <string>Resources/Fonts</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>MacClock needs your location to show local weather conditions.</string>
    <key>NSLocationUsageDescription</key>
    <string>MacClock needs your location to show local weather conditions.</string>
    <key>NSCalendarsUsageDescription</key>
    <string>MacClock needs calendar access to display your upcoming events.</string>
</dict>
</plist>
```

**Step 2: Verify build**

Run: `swift build`
Expected: PASS

**Step 3: Commit**

```bash
git add MacClock/Info.plist
git commit -m "fix(calendar): add NSCalendarsUsageDescription for permission dialog"
```

---

### Task 2: Create ICalFeed Model

**Files:**
- Create: `MacClock/Models/ICalFeed.swift`
- Test: `MacClockTests/ICalFeedTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/ICalFeedTests.swift`:

```swift
import Testing
import Foundation
@testable import MacClock

@Suite("ICalFeed Tests")
struct ICalFeedTests {
    @Test("ICalFeed stores properties correctly")
    func iCalFeedStoresProperties() {
        let feed = ICalFeed(
            id: UUID(),
            name: "Test Calendar",
            url: "https://example.com/calendar.ics",
            isEnabled: true,
            colorHex: "#FF0000"
        )
        #expect(feed.name == "Test Calendar")
        #expect(feed.url == "https://example.com/calendar.ics")
        #expect(feed.isEnabled == true)
        #expect(feed.colorHex == "#FF0000")
    }

    @Test("ICalFeed is Codable")
    func iCalFeedIsCodable() throws {
        let feed = ICalFeed(
            id: UUID(),
            name: "Work",
            url: "https://example.com/work.ics",
            isEnabled: true,
            colorHex: "#0000FF"
        )
        let data = try JSONEncoder().encode(feed)
        let decoded = try JSONDecoder().decode(ICalFeed.self, from: data)
        #expect(decoded.name == feed.name)
        #expect(decoded.url == feed.url)
        #expect(decoded.colorHex == feed.colorHex)
    }

    @Test("ICalFeed color presets are available")
    func colorPresetsAvailable() {
        let presets = ICalFeed.colorPresets
        #expect(presets.count >= 8)
        #expect(presets.contains { $0.name == "Red" })
        #expect(presets.contains { $0.name == "Blue" })
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ICalFeedTests`
Expected: FAIL - ICalFeed doesn't exist

**Step 3: Create ICalFeed model**

Create `MacClock/Models/ICalFeed.swift`:

```swift
import Foundation
import SwiftUI

struct ICalFeed: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var isEnabled: Bool
    var colorHex: String

    struct ColorPreset: Identifiable {
        let id = UUID()
        let name: String
        let hex: String
    }

    static let colorPresets: [ColorPreset] = [
        ColorPreset(name: "Red", hex: "#FF3B30"),
        ColorPreset(name: "Orange", hex: "#FF9500"),
        ColorPreset(name: "Yellow", hex: "#FFCC00"),
        ColorPreset(name: "Green", hex: "#34C759"),
        ColorPreset(name: "Blue", hex: "#007AFF"),
        ColorPreset(name: "Purple", hex: "#AF52DE"),
        ColorPreset(name: "Pink", hex: "#FF2D55"),
        ColorPreset(name: "Gray", hex: "#8E8E93"),
    ]
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ICalFeedTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/ICalFeed.swift MacClockTests/ICalFeedTests.swift
git commit -m "feat(calendar): add ICalFeed model for online calendars"
```

---

### Task 3: Add iCalFeeds to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`

**Step 1: Add iCalFeeds property**

In `MacClock/Models/AppSettings.swift`, add the new property after `selectedCalendarIDs` (around line 223):

```swift
    var iCalFeeds: [ICalFeed] {
        didSet {
            if let data = try? JSONEncoder().encode(iCalFeeds) {
                defaults.set(data, forKey: "iCalFeeds")
            }
        }
    }
```

**Step 2: Initialize in init()**

In the `init()` method, add after the `selectedCalendarIDs` initialization (around line 309):

```swift
        if let data = defaults.data(forKey: "iCalFeeds"),
           let feeds = try? JSONDecoder().decode([ICalFeed].self, from: data) {
            self.iCalFeeds = feeds
        } else {
            self.iCalFeeds = []
        }
```

**Step 3: Verify build**

Run: `swift build`
Expected: PASS

**Step 4: Commit**

```bash
git add MacClock/Models/AppSettings.swift
git commit -m "feat(calendar): add iCalFeeds property to AppSettings"
```

---

### Task 4: Create ICalService with ICS Parsing

**Files:**
- Create: `MacClock/Services/ICalService.swift`
- Test: `MacClockTests/ICalServiceTests.swift`

**Step 1: Write the failing tests**

Create `MacClockTests/ICalServiceTests.swift`:

```swift
import Testing
import Foundation
@testable import MacClock

@Suite("ICalService Tests")
struct ICalServiceTests {
    @Test("Parses simple VEVENT")
    func parsesSimpleEvent() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:test-event-1@example.com
        DTSTART:20260129T100000Z
        DTEND:20260129T110000Z
        SUMMARY:Team Meeting
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")

        #expect(events.count == 1)
        #expect(events[0].title == "Team Meeting")
        #expect(events[0].calendarTitle == "Test")
    }

    @Test("Parses all-day event")
    func parsesAllDayEvent() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:all-day-1@example.com
        DTSTART;VALUE=DATE:20260129
        DTEND;VALUE=DATE:20260130
        SUMMARY:Holiday
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#0000FF")

        #expect(events.count == 1)
        #expect(events[0].title == "Holiday")
        #expect(events[0].isAllDay == true)
    }

    @Test("Parses multiple events")
    func parsesMultipleEvents() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:event-1@example.com
        DTSTART:20260129T090000Z
        DTEND:20260129T100000Z
        SUMMARY:Morning Standup
        END:VEVENT
        BEGIN:VEVENT
        UID:event-2@example.com
        DTSTART:20260129T140000Z
        DTEND:20260129T150000Z
        SUMMARY:Afternoon Review
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Work", colorHex: "#00FF00")

        #expect(events.count == 2)
    }

    @Test("Handles missing SUMMARY gracefully")
    func handlesMissingSummary() {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:no-title@example.com
        DTSTART:20260129T100000Z
        DTEND:20260129T110000Z
        END:VEVENT
        END:VCALENDAR
        """

        let service = ICalService()
        let events = service.parseICS(ics, feedName: "Test", colorHex: "#FF0000")

        #expect(events.count == 1)
        #expect(events[0].title == "Untitled")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ICalServiceTests`
Expected: FAIL - ICalService doesn't exist

**Step 3: Create ICalService**

Create `MacClock/Services/ICalService.swift`:

```swift
import Foundation

actor ICalService {
    private let session = URLSession.shared

    /// Fetch events from an iCal feed URL
    func fetchEvents(from feed: ICalFeed) async throws -> [CalendarEvent] {
        guard feed.isEnabled else { return [] }
        guard let url = URL(string: feed.url) else {
            throw ICalError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw ICalError.invalidContent
        }

        return parseICS(content, feedName: feed.name, colorHex: feed.colorHex)
    }

    /// Parse ICS content into CalendarEvent array
    nonisolated func parseICS(_ content: String, feedName: String, colorHex: String) -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        let lines = content.components(separatedBy: .newlines)

        var inEvent = false
        var currentEvent: [String: String] = [:]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
            } else if trimmed == "END:VEVENT" {
                if inEvent {
                    if let event = createEvent(from: currentEvent, feedName: feedName, colorHex: colorHex) {
                        events.append(event)
                    }
                }
                inEvent = false
            } else if inEvent {
                // Parse property:value or property;params:value
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let keyPart = String(trimmed[..<colonIndex])
                    let value = String(trimmed[trimmed.index(after: colonIndex)...])

                    // Handle properties with parameters (e.g., DTSTART;VALUE=DATE:20260129)
                    let key = keyPart.components(separatedBy: ";").first ?? keyPart
                    currentEvent[key] = value

                    // Check for VALUE=DATE parameter (all-day events)
                    if keyPart.contains("VALUE=DATE") {
                        currentEvent[key + "_ALLDAY"] = "true"
                    }
                }
            }
        }

        return events
    }

    private nonisolated func createEvent(from properties: [String: String], feedName: String, colorHex: String) -> CalendarEvent? {
        guard let dtstart = properties["DTSTART"] else { return nil }

        let uid = properties["UID"] ?? UUID().uuidString
        let summary = properties["SUMMARY"] ?? "Untitled"
        let isAllDay = properties["DTSTART_ALLDAY"] == "true"

        let startDate: Date
        let endDate: Date

        if isAllDay {
            // All-day format: 20260129
            guard let start = parseDate(dtstart) else { return nil }
            startDate = start
            if let dtend = properties["DTEND"], let end = parseDate(dtend) {
                endDate = end
            } else {
                endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
            }
        } else {
            // DateTime format: 20260129T100000Z or 20260129T100000
            guard let start = parseDateTime(dtstart) else { return nil }
            startDate = start
            if let dtend = properties["DTEND"], let end = parseDateTime(dtend) {
                endDate = end
            } else {
                endDate = startDate.addingTimeInterval(3600) // Default 1 hour
            }
        }

        let color = colorFromHex(colorHex)

        return CalendarEvent(
            id: uid,
            title: summary,
            startDate: startDate,
            endDate: endDate,
            calendarTitle: feedName,
            calendarColor: color,
            isAllDay: isAllDay
        )
    }

    private nonisolated func parseDate(_ string: String) -> Date? {
        // Format: 20260129
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }

    private nonisolated func parseDateTime(_ string: String) -> Date? {
        var dateString = string

        // Handle timezone suffix
        let isUTC = dateString.hasSuffix("Z")
        if isUTC {
            dateString = String(dateString.dropLast())
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = isUTC ? TimeZone(identifier: "UTC") : TimeZone.current

        return formatter.date(from: dateString)
    }

    private nonisolated func colorFromHex(_ hex: String) -> CGColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        return CGColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

enum ICalError: Error, LocalizedError {
    case invalidURL
    case invalidContent
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid calendar URL"
        case .invalidContent: return "Could not read calendar content"
        case .networkError: return "Network error fetching calendar"
        }
    }
}
```

**Step 4: Update CalendarEvent with additional initializer**

Add to `MacClock/Models/CalendarEvent.swift` after the existing `init(from:)`:

```swift
    init(id: String, title: String, startDate: Date, endDate: Date, calendarTitle: String, calendarColor: CGColor?, isAllDay: Bool) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarTitle = calendarTitle
        self.calendarColor = calendarColor
        self.isAllDay = isAllDay
    }
```

**Step 5: Run test to verify it passes**

Run: `swift test --filter ICalServiceTests`
Expected: PASS

**Step 6: Commit**

```bash
git add MacClock/Services/ICalService.swift MacClock/Models/CalendarEvent.swift MacClockTests/ICalServiceTests.swift
git commit -m "feat(calendar): add ICalService with ICS parsing"
```

---

### Task 5: Add Calendar Tab to Settings

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add calendar case to SettingsTab enum**

In `MacClock/Views/SettingsView.swift`, update the `SettingsTab` enum (around line 6-26):

```swift
enum SettingsTab: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case window = "Window"
    case location = "Location"
    case worldClocks = "World Clocks"
    case calendar = "Calendar"
    case news = "News"
    case extras = "Extras"

    var icon: String {
        switch self {
        case .general: return "clock.fill"
        case .appearance: return "paintbrush.fill"
        case .window: return "macwindow"
        case .location: return "location.fill"
        case .worldClocks: return "globe"
        case .calendar: return "calendar"
        case .news: return "newspaper.fill"
        case .extras: return "sparkles"
        }
    }
}
```

**Step 2: Add case to tab content switch**

In the `SettingsView` body, add the calendar case to the switch statement (add between worldClocks and news cases):

```swift
                    case .calendar:
                        CalendarTabView(settings: settings, calendarService: calendarService)
```

**Step 3: Add calendarService property to SettingsView**

The calendarService is currently created in ExtrasTabView. Move it to SettingsView so both tabs can use it. Add after `locationService`:

```swift
    @State private var calendarService = CalendarService()
```

Then update the ExtrasTabView usage to pass it.

**Step 4: Verify build**

Run: `swift build`
Expected: FAIL - CalendarTabView doesn't exist yet (expected)

**Step 5: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat(calendar): add Calendar tab to Settings tabs enum"
```

---

### Task 6: Create CalendarTabView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Create CalendarTabView struct**

Add this struct to `MacClock/Views/SettingsView.swift` (after NewsTabView, before ExtrasTabView):

```swift
// MARK: - Calendar Tab

struct CalendarTabView: View {
    @Bindable var settings: AppSettings
    let calendarService: CalendarService
    @State private var showAddFeed = false
    @State private var editingFeed: ICalFeed?

    var body: some View {
        SettingsSection(title: "Display") {
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
                    .frame(width: 120)
                }
            }
        }

        SettingsSection(title: "Local Calendars") {
            if calendarService.authorizationStatus != .fullAccess && calendarService.authorizationStatus != .authorized {
                Button("Grant Calendar Access") {
                    Task { await calendarService.requestAccess() }
                }
                .buttonStyle(.borderedProminent)

                Text("Allow access to show events from your Mac's calendars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if calendarService.availableCalendars.isEmpty {
                Text("No calendars found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                    HStack {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor ?? CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)))
                            .frame(width: 10, height: 10)

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

        SettingsSection(title: "Online Calendars (iCal)") {
            if settings.iCalFeeds.isEmpty {
                Text("No online calendars added")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($settings.iCalFeeds) { $feed in
                    ICalFeedRow(feed: $feed, onEdit: {
                        editingFeed = feed
                    }, onDelete: {
                        settings.iCalFeeds.removeAll { $0.id == feed.id }
                    })
                }
            }

            Button {
                showAddFeed = true
            } label: {
                Label("Add iCal URL", systemImage: "plus.circle")
            }
            .padding(.top, 4)
        }
        .sheet(isPresented: $showAddFeed) {
            AddICalFeedSheet(isPresented: $showAddFeed) { feed in
                settings.iCalFeeds.append(feed)
            }
        }
        .sheet(item: $editingFeed) { feed in
            EditICalFeedSheet(feed: feed, isPresented: Binding(
                get: { editingFeed != nil },
                set: { if !$0 { editingFeed = nil } }
            )) { updatedFeed in
                if let index = settings.iCalFeeds.firstIndex(where: { $0.id == updatedFeed.id }) {
                    settings.iCalFeeds[index] = updatedFeed
                }
            }
        }
    }
}

// MARK: - iCal Feed Row

struct ICalFeedRow: View {
    @Binding var feed: ICalFeed
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: feed.colorHex) ?? .blue)
                .frame(width: 10, height: 10)

            Toggle("", isOn: $feed.isEnabled)
                .labelsHidden()
                .toggleStyle(.checkbox)

            Text(feed.name)

            Spacer()

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
                            .fill(Color(hex: preset.hex) ?? .blue)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: selectedColorHex == preset.hex ? 2 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("To find your Google Calendar URL: Calendar Settings → [calendar] → \"Secret address in iCal format\"")
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
                            .fill(Color(hex: preset.hex) ?? .blue)
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
```

**Step 2: Add Color(hex:) extension if not present**

Check if `Color(hex:)` extension exists. If not, add to the file or a shared location:

```swift
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
```

**Step 3: Verify build**

Run: `swift build`
Expected: PASS

**Step 4: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat(calendar): add CalendarTabView with local and online calendar management"
```

---

### Task 7: Remove Calendar from ExtrasTabView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Update ExtrasTabView to remove Calendar section**

Replace the `ExtrasTabView` struct to only contain Alarms:

```swift
// MARK: - Extras Tab

struct ExtrasTabView: View {
    @Bindable var settings: AppSettings
    @Binding var showAlarmPanel: Bool

    var body: some View {
        SettingsSection(title: "Alarms & Timers") {
            Button("Open Alarms, Timer & Stopwatch") {
                showAlarmPanel = true
            }
        }
    }
}
```

**Step 2: Update ExtrasTabView usage in SettingsView**

Update the switch case for `.extras` to not pass `calendarService`:

```swift
                    case .extras:
                        ExtrasTabView(
                            settings: settings,
                            showAlarmPanel: $showAlarmPanel
                        )
```

**Step 3: Verify build**

Run: `swift build`
Expected: PASS

**Step 4: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "refactor(calendar): remove Calendar section from ExtrasTabView"
```

---

### Task 8: Update MainClockView to Fetch iCal Events

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add ICalService state**

In `MainClockView`, add after other service declarations:

```swift
    @State private var iCalService = ICalService()
    @State private var iCalEvents: [CalendarEvent] = []
    @State private var iCalTimer: Timer?
```

**Step 2: Update loadCalendarEvents to include iCal feeds**

Replace the `loadCalendarEvents` function:

```swift
    private func loadCalendarEvents() {
        // Local calendar events
        nextEvent = calendarService.fetchNextEvent(from: settings.selectedCalendarIDs)
        var allEvents = calendarService.fetchTodayEvents(from: settings.selectedCalendarIDs)

        // Fetch iCal events
        Task {
            var fetchedEvents: [CalendarEvent] = []
            for feed in settings.iCalFeeds where feed.isEnabled {
                do {
                    let events = try await iCalService.fetchEvents(from: feed)
                    // Filter to today's events
                    let today = Calendar.current.startOfDay(for: Date())
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
                    let todayEvents = events.filter { $0.startDate >= today && $0.startDate < tomorrow }
                    fetchedEvents.append(contentsOf: todayEvents)
                } catch {
                    print("Failed to fetch iCal feed \(feed.name): \(error)")
                }
            }

            await MainActor.run {
                iCalEvents = fetchedEvents
                // Merge and sort all events
                todayEvents = (allEvents + iCalEvents).sorted { $0.startDate < $1.startDate }
                // Update next event to include iCal events
                let now = Date()
                nextEvent = todayEvents.first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }
            }
        }

        todayEvents = allEvents
    }
```

**Step 3: Add iCal refresh timer in onAppear**

In the `onAppear` block, add after calendar event loading:

```swift
            // Setup iCal refresh timer (every 15 minutes)
            iCalTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { _ in
                loadCalendarEvents()
            }
```

**Step 4: Invalidate timer in onDisappear**

Add to `onDisappear`:

```swift
            iCalTimer?.invalidate()
```

**Step 5: Add onChange for iCalFeeds**

Add an onChange handler to refresh when feeds change:

```swift
        .onChange(of: settings.iCalFeeds) { _, _ in
            loadCalendarEvents()
        }
```

**Step 6: Verify build**

Run: `swift build`
Expected: PASS

**Step 7: Commit**

```bash
git add MacClock/MacClockApp.swift
git commit -m "feat(calendar): integrate iCal feeds into event display"
```

---

### Task 9: Run All Tests and Final Verification

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 2: Build the app**

Run: `swift build`
Expected: Build successful

**Step 3: Final commit if any uncommitted changes**

```bash
git status
# If any changes:
git add -A
git commit -m "feat(calendar): complete Calendar tab implementation"
```

---

## Summary

This plan implements:
1. ✅ Fix native calendar access with `NSCalendarsUsageDescription`
2. ✅ `ICalFeed` model for online calendar configuration
3. ✅ `ICalService` with ICS/iCal parsing
4. ✅ `iCalFeeds` property in AppSettings
5. ✅ New "Calendar" tab in Settings
6. ✅ `CalendarTabView` with local and online calendar management
7. ✅ Add/Edit iCal feed sheets
8. ✅ Remove Calendar from Extras tab
9. ✅ Integrate iCal events into main clock display
