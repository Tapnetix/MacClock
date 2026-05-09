import SwiftUI

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
                ForEach(Array(settings.worldClocks.enumerated()), id: \.element.id) { index, clock in
                    HStack(spacing: 8) {
                        // Move up/down buttons
                        VStack(spacing: 0) {
                            Button {
                                guard index > 0 else { return }
                                settings.worldClocks.swapAt(index, index - 1)
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(index > 0 ? .secondary : .quaternary)
                            }
                            .buttonStyle(.plain)
                            .disabled(index == 0)

                            Button {
                                guard index < settings.worldClocks.count - 1 else { return }
                                settings.worldClocks.swapAt(index, index + 1)
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(index < settings.worldClocks.count - 1 ? .secondary : .quaternary)
                            }
                            .buttonStyle(.plain)
                            .disabled(index >= settings.worldClocks.count - 1)
                        }

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
