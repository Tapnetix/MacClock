import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var citySearch = ""
    @State private var searchError: String?
    @FocusState private var isCityFieldFocused: Bool
    @State private var showCityPicker = false
    @State private var citySearchService = CitySearchService()

    var body: some View {
        Form {
            Section("Display") {
                Picker("Clock Style", selection: $settings.clockStyle) {
                    ForEach(ClockStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                Toggle("24-Hour Time", isOn: $settings.use24Hour)
                Toggle("Show Seconds", isOn: $settings.showSeconds)
                Picker("Temperature", selection: $settings.useCelsius) {
                    Text("°F").tag(false)
                    Text("°C").tag(true)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("Clock Size: \(Int(settings.clockFontSize))")
                    Slider(value: $settings.clockFontSize, in: 48...200, step: 4)
                }

                if !settings.autoThemeEnabled {
                    Picker("Theme", selection: $settings.colorTheme) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
            }

            Section("Appearance") {
                Toggle("Auto-Dim", isOn: $settings.autoDimEnabled)

                if settings.autoDimEnabled {
                    Picker("Trigger", selection: $settings.autoDimMode) {
                        ForEach(AutoDimMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    if settings.autoDimMode == .fixedSchedule {
                        Picker("Dim at", selection: $settings.dimStartHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }

                        Picker("Brighten at", selection: $settings.dimEndHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Dim Level: \(Int(settings.autoDimLevel * 100))%")
                        Slider(value: $settings.autoDimLevel, in: 0.2...0.8, step: 0.1)
                    }

                    Picker("Night Theme", selection: Binding(
                        get: { settings.nightTheme ?? .warmAmber },
                        set: { settings.nightTheme = $0 }
                    )) {
                        Text("None").tag(Optional<ColorTheme>.none)
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(Optional(theme))
                        }
                    }
                }

                Divider()

                Toggle("Auto Theme Switching", isOn: $settings.autoThemeEnabled)

                if settings.autoThemeEnabled {
                    Picker("Day Theme", selection: $settings.dayTheme) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }

                    Picker("Night Theme", selection: $settings.nightThemeAuto) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }

                    Picker("Switch at", selection: $settings.autoThemeMode) {
                        ForEach(AutoDimMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
            }

            Section("Window") {
                Picker("Behavior", selection: $settings.windowLevel) {
                    ForEach(WindowLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Opacity: \(Int(settings.windowOpacity * 100))%")
                    Slider(value: $settings.windowOpacity, in: 0.2...1.0, step: 0.1)
                }
            }

            Section("Location") {
                Toggle("Auto-detect Location", isOn: $settings.useAutoLocation)

                if !settings.useAutoLocation {
                    HStack {
                        TextField("City name", text: $citySearch)
                            .textFieldStyle(.roundedBorder)
                            .focused($isCityFieldFocused)

                        Button("Search") {
                            Task { await searchCity() }
                        }
                    }
                    .onAppear {
                        // Ensure the sheet window can receive keyboard input
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }

                    if !settings.manualLocationName.isEmpty {
                        Text("Current: \(settings.manualLocationName)")
                            .foregroundStyle(.secondary)
                    }

                    if let error = searchError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }

            Section("Background") {
                Picker("Mode", selection: $settings.backgroundMode) {
                    ForEach(BackgroundMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                if settings.backgroundMode == .nature {
                    VStack(alignment: .leading) {
                        Text("Cycle every: \(Int(settings.backgroundCycleInterval))s")
                        Slider(value: $settings.backgroundCycleInterval, in: 10...300, step: 10)
                    }
                }

                if settings.backgroundMode == .custom {
                    HStack {
                        Text(settings.customBackgroundPath ?? "None selected")
                            .foregroundStyle(settings.customBackgroundPath == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

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

            Section("System") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showCityPicker) {
            CityPickerSheet(
                settings: settings,
                searchService: citySearchService,
                isPresented: $showCityPicker
            )
        }
        .frame(width: 350, height: 700)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
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

#Preview {
    SettingsView(settings: AppSettings(), locationService: LocationService())
}
