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

    var body: some View {
        Form {
            Section("Display") {
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
            }

            Section("Window") {
                Picker("Behavior", selection: $settings.windowLevel) {
                    ForEach(WindowLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
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
                HStack {
                    Text(settings.customBackgroundPath ?? "Default (time-based)")
                        .foregroundStyle(settings.customBackgroundPath == nil ? .secondary : .primary)

                    Spacer()

                    Button("Choose...") {
                        selectCustomBackground()
                    }

                    if settings.customBackgroundPath != nil {
                        Button("Reset") {
                            settings.customBackgroundPath = nil
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
        .frame(width: 400, height: 450)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
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

#Preview {
    SettingsView(settings: AppSettings(), locationService: LocationService())
}
