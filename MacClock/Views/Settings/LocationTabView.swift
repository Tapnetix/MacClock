import SwiftUI
import AppKit

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
                                settings.customBackgroundBookmark = nil
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

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Persist a bookmark so the path keeps working after relaunch
        // and any future sandboxing change.
        do {
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            settings.customBackgroundBookmark = bookmark
            settings.customBackgroundPath = url.path  // mirror for display only
        } catch {
            // Fall back to a non-security-scoped bookmark for unsigned builds.
            if let bookmark = try? url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                settings.customBackgroundBookmark = bookmark
                settings.customBackgroundPath = url.path
            }
        }
    }
}
