import SwiftUI
import ServiceManagement
import AppKit
import EventKit

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

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let locationService: LocationService

    @State private var selectedTab: SettingsTab = .general
    @State private var citySearch = ""
    @State private var searchError: String?
    @FocusState private var isCityFieldFocused: Bool
    @State private var showCityPicker = false
    @State private var citySearchService = CitySearchService()
    @State private var calendarService = CalendarService()
    @State private var showAlarmPanel = false
    @State private var alarmService = AlarmService()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar-style tab bar
            HStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    SettingsTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Divider()

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .general:
                        GeneralTabView(settings: settings)
                    case .appearance:
                        AppearanceTabView(settings: settings)
                    case .window:
                        WindowTabView(settings: settings)
                    case .location:
                        LocationTabView(
                            settings: settings,
                            locationService: locationService,
                            citySearch: $citySearch,
                            searchError: $searchError,
                            isCityFieldFocused: _isCityFieldFocused
                        )
                    case .worldClocks:
                        WorldClocksTabView(
                            settings: settings,
                            showCityPicker: $showCityPicker
                        )
                    case .calendar:
                        CalendarTabView(settings: settings, calendarService: calendarService)
                    case .news:
                        NewsTabView(settings: settings)
                    case .extras:
                        ExtrasTabView(
                            settings: settings,
                            showAlarmPanel: $showAlarmPanel
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 420, height: 400)
        .sheet(isPresented: $showCityPicker) {
            CityPickerSheet(
                settings: settings,
                searchService: citySearchService,
                isPresented: $showCityPicker
            )
        }
        .sheet(isPresented: $showAlarmPanel) {
            AlarmPanelView(settings: settings, alarmService: alarmService)
        }
    }
}

// MARK: - Tab Button

struct SettingsTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                    .frame(height: 20)
                Text(tab.rawValue)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab

struct GeneralTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SettingsSection(title: "Clock Display") {
            LabeledContent("Style") {
                Picker("", selection: $settings.clockStyle) {
                    ForEach(ClockStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            LabeledContent("Size") {
                HStack {
                    Slider(value: $settings.clockFontSize, in: 48...200, step: 4)
                        .frame(width: 120)
                    Text("\(Int(settings.clockFontSize))")
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                }
            }

            Toggle("24-Hour Time", isOn: $settings.use24Hour)
            Toggle("Show Seconds", isOn: $settings.showSeconds)
        }

        SettingsSection(title: "Temperature") {
            Picker("", selection: $settings.useCelsius) {
                Text("Fahrenheit (°F)").tag(false)
                Text("Celsius (°C)").tag(true)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
        }

        SettingsSection(title: "Weather Details") {
            Toggle("Enable weather detail panel", isOn: $settings.weatherDetailEnabled)
                .help("Click on temperature to show/hide detailed forecast")

            if settings.weatherDetailEnabled {
                Text("Show in panel:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Toggle("Current conditions (feels like, humidity, high/low)", isOn: $settings.weatherShowCurrentDetails)
                    .padding(.leading, 16)
                Toggle("Sunrise & sunset", isOn: $settings.weatherShowSunriseSunset)
                    .padding(.leading, 16)
                Toggle("Hourly forecast (6 hours)", isOn: $settings.weatherShowHourly)
                    .padding(.leading, 16)
                Toggle("Daily forecast (3 days)", isOn: $settings.weatherShowDaily)
                    .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Appearance Tab

struct AppearanceTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SettingsSection(title: "Theme") {
            if !settings.autoThemeEnabled {
                LabeledContent("Color Theme") {
                    Picker("", selection: $settings.colorTheme) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
            }

            Toggle("Auto Theme Switching", isOn: $settings.autoThemeEnabled)

            if settings.autoThemeEnabled {
                LabeledContent("Day Theme") {
                    Picker("", selection: $settings.dayTheme) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                LabeledContent("Night Theme") {
                    Picker("", selection: $settings.nightThemeAuto) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                LabeledContent("Switch Based On") {
                    Picker("", selection: $settings.autoThemeMode) {
                        ForEach(AutoDimMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
            }
        }

        SettingsSection(title: "Auto-Dim") {
            Toggle("Enable Auto-Dim", isOn: $settings.autoDimEnabled)

            if settings.autoDimEnabled {
                LabeledContent("Trigger") {
                    Picker("", selection: $settings.autoDimMode) {
                        ForEach(AutoDimMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                if settings.autoDimMode == .fixedSchedule {
                    LabeledContent("Dim at") {
                        Picker("", selection: $settings.dimStartHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }

                    LabeledContent("Brighten at") {
                        Picker("", selection: $settings.dimEndHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                }

                LabeledContent("Dim Level") {
                    HStack {
                        Slider(value: $settings.autoDimLevel, in: 0.2...0.8, step: 0.1)
                            .frame(width: 100)
                        Text("\(Int(settings.autoDimLevel * 100))%")
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
                    }
                }

                LabeledContent("Night Theme") {
                    Picker("", selection: Binding(
                        get: { settings.nightTheme ?? .warmAmber },
                        set: { settings.nightTheme = $0 }
                    )) {
                        Text("None").tag(Optional<ColorTheme>.none)
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(Optional(theme))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Window Tab

struct WindowTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SettingsSection(title: "Window Behavior") {
            LabeledContent("Window Level") {
                Picker("", selection: $settings.windowLevel) {
                    ForEach(WindowLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            LabeledContent("Opacity") {
                HStack {
                    Slider(value: $settings.windowOpacity, in: 0.2...1.0, step: 0.1)
                        .frame(width: 120)
                    Text("\(Int(settings.windowOpacity * 100))%")
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                }
            }
        }

        SettingsSection(title: "System") {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    updateLaunchAtLogin(newValue)
                }
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}

// MARK: - Location Tab

struct LocationTabView: View {
    @Bindable var settings: AppSettings
    let locationService: LocationService
    @Binding var citySearch: String
    @Binding var searchError: String?
    @FocusState var isCityFieldFocused: Bool

    var body: some View {
        SettingsSection(title: "Location") {
            Toggle("Auto-detect Location", isOn: $settings.useAutoLocation)

            if !settings.useAutoLocation {
                HStack {
                    TextField("City name", text: $citySearch)
                        .textFieldStyle(.roundedBorder)
                        .focused($isCityFieldFocused)
                        .frame(width: 180)

                    Button("Search") {
                        Task { await searchCity() }
                    }
                }

                if !settings.manualLocationName.isEmpty {
                    Text("Current: \(settings.manualLocationName)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                if let error = searchError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }

        SettingsSection(title: "Background") {
            LabeledContent("Mode") {
                Picker("", selection: $settings.backgroundMode) {
                    ForEach(BackgroundMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            if settings.backgroundMode == .nature {
                LabeledContent("Cycle Interval") {
                    HStack {
                        Slider(value: $settings.backgroundCycleInterval, in: 10...300, step: 10)
                            .frame(width: 100)
                        Text("\(Int(settings.backgroundCycleInterval))s")
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
                    }
                }
            }

            if settings.backgroundMode == .custom {
                LabeledContent("Image") {
                    HStack {
                        Text(settings.customBackgroundPath?.split(separator: "/").last.map(String.init) ?? "None")
                            .foregroundStyle(settings.customBackgroundPath == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .frame(width: 100, alignment: .leading)

                        Button("Choose...") {
                            selectCustomBackground()
                        }

                        if settings.customBackgroundPath != nil {
                            Button("Clear") {
                                settings.customBackgroundPath = nil
                            }
                        }
                    }
                }
            }
        }
    }

    private func searchCity() async {
        do {
            searchError = nil
            let result = try await locationService.geocodeCity(name: citySearch)
            settings.manualLatitude = result.latitude
            settings.manualLongitude = result.longitude
            settings.manualLocationName = result.name
            citySearch = ""
        } catch {
            searchError = "City not found"
        }
    }

    private func selectCustomBackground() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .folder]

        if panel.runModal() == .OK {
            settings.customBackgroundPath = panel.url?.path
        }
    }
}

// MARK: - World Clocks Tab

struct WorldClocksTabView: View {
    @Bindable var settings: AppSettings
    @Binding var showCityPicker: Bool

    var body: some View {
        SettingsSection(title: "World Clocks") {
            Toggle("Enable World Clocks", isOn: $settings.worldClocksEnabled)

            if settings.worldClocksEnabled {
                LabeledContent("Position") {
                    Picker("", selection: $settings.worldClocksPosition) {
                        ForEach(WorldClocksPosition.allCases, id: \.self) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }

                Toggle("Show Timezone Abbreviation", isOn: $settings.showTimezoneAbbreviation)
                Toggle("Show Day Difference", isOn: $settings.showDayDifference)
            }
        }

        if settings.worldClocksEnabled {
            SettingsSection(title: "Cities") {
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

                if settings.worldClocks.isEmpty {
                    Text("No cities added")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                if settings.worldClocks.count < 5 {
                    Button {
                        showCityPicker = true
                    } label: {
                        Label("Add City", systemImage: "plus.circle.fill")
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Calendar Tab

struct CalendarTabView: View {
    @Bindable var settings: AppSettings
    let calendarService: CalendarService
    @State private var showAddFeed = false
    @State private var editingFeed: ICalFeed?
    @State private var testingFeed: ICalFeed?

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
                    ICalFeedRow(feed: $feed, onTest: {
                        testingFeed = feed
                    }, onEdit: {
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
        .sheet(item: $testingFeed) { feed in
            TestICalFeedSheet(feed: feed, isPresented: Binding(
                get: { testingFeed != nil },
                set: { if !$0 { testingFeed = nil } }
            ))
        }
    }
}

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

            Text("URL: \(feed.url)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
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

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - City Picker Sheet

struct CityPickerSheet: View {
    let settings: AppSettings
    let searchService: CitySearchService
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var searchResults: [CitySearchResult] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add City")
                    .font(.headline)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            TextField("Search city...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
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
            .listStyle(.plain)
        }
        .frame(width: 350, height: 400)
        .task {
            searchResults = await searchService.allCities()
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings(), locationService: LocationService())
}
